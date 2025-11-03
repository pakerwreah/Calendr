//
//  CalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import RxSwift
import EventKit
import Sentry

protocol CalendarServiceProviding {

    var changeObservable: Observable<Void> { get }

    func calendars() -> Single<[CalendarModel]>
    func events(from start: Date, to end: Date, calendars: [String]) -> Single<[EventModel]>

    func createReminder(title: String, date: Date) -> Completable
    func completeReminder(id: String, complete: Bool) -> Completable
    func rescheduleReminder(id: String, to: Date) -> Completable

    func changeEventStatus(id: String, date: Date, to: EventStatus) -> Completable

    @MainActor func requestAccess()
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let dateProvider: DateProviding
    private let workspace: WorkspaceServiceProviding
    private let localStorage: LocalStorageProvider
    private let notificationCenter: NotificationCenter

    private let store = EventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>
    let changeObservable: Observable<Void>

    init(
        dateProvider: DateProviding,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider,
        notificationCenter: NotificationCenter
    ) {
        self.dateProvider = dateProvider
        self.workspace = workspace
        self.localStorage = localStorage
        self.notificationCenter = notificationCenter

        (changeObservable, changeObserver) = PublishSubject.pipe(on: MainScheduler.instance)
    }

    private func listenToStoreChanges() {

        let interval = Observable<Int>.interval(.seconds(60), scheduler: MainScheduler.instance).void()
        let eventStoreChanged = notificationCenter.rx.notification(.EKEventStoreChanged, object: store).void()

        Observable.merge(interval, eventStoreChanged)
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    @discardableResult
    private func openPrivacySettings(for entity: PrivacyEntity) -> Bool {

        guard !localStorage.permissionSuppressed.contains(entity.rawValue) else {
            return false
        }

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = Strings.AccessRequired.message(for: entity)
        alert.addButton(withTitle: Strings.AccessRequired.openSettings)
        alert.addButton(withTitle: Strings.AccessRequired.cancel)
        alert.showsSuppressionButton = true
        let result = alert.runModal()

        if result == .alertFirstButtonReturn {
            return workspace.open(.privacySettings(for: entity))
        }

        if alert.suppressionButton?.state == .on {
            localStorage.permissionSuppressed.append(entity.rawValue)
        }

        return false
    }

    func requestAccess() {
        Task {
            listenToStoreChanges()

            let events = await requestAccess(to: .event)
            let reminders = await requestAccess(to: .reminder)

            if !events {
                if self.openPrivacySettings(for: .calendars) {
                    return
                }
            }
            if !reminders {
                self.openPrivacySettings(for: .reminders)
            }
        }
    }

    private func requestAccess(to type: EKEntityType) async -> Bool {
        do {
            let granted = try await store.requestAccess(to: type)

            if granted {
                print("Access granted for \(type)!")
            } else {
                print("Access denied for \(type)!")
            }

            return granted
        } catch {
            print(error.localizedDescription)
            SentrySDK.capture(error: error)
            return false
        }
    }

    private func storeCalendars(with ids: [String]? = nil) -> Single<[EKCalendar]> {

        Single.create { [store] observer in

            var calendars: [EKCalendar] = []

            for type in [.event, .reminder] as [EKEntityType] where store.hasAccess(to: type) {
                calendars.append(contentsOf: store.calendars(for: type))
            }

            if let ids {
                calendars = calendars.filter { ids.contains($0.calendarIdentifier) }
            }

            observer(.success(calendars))

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func calendars() -> Single<[CalendarModel]> {

        storeCalendars().map { $0.map(CalendarModel.init(from:)) }
    }

    func events(from start: Date, to end: Date, calendars ids: [String]) -> Single<[EventModel]> {

        storeCalendars(with: ids)
            .flatMap { [weak self] calendars -> Single<[EventModel]> in
                guard let self, !calendars.isEmpty else { return .just([]) }

                return Single.zip(
                    fetchEvents(from: start, to: end, calendars: calendars),
                    fetchReminders(from: start, to: end, calendars: calendars)
                )
                .map(+)
            }
    }

    private func fetchEvents(from start: Date, to end: Date, calendars: [EKCalendar]) -> Single<[EventModel]> {

        guard store.hasAccess(to: .event) else { return .just([]) }

        return Single.create { [store, dateProvider] observer in

            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)

            let events = store.events(matching: predicate).compactMap { EventModel(from: $0, dateProvider: dateProvider) }

            observer(.success(events))

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    private func fetchReminders(from start: Date, to end: Date, calendars: [EKCalendar]) -> Single<[EventModel]> {

        guard store.hasAccess(to: .reminder) else { return .just([]) }

        let incomplete = Single.create { [store] observer in

            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: start, ending: end, calendars: calendars
            )

            store.fetchReminders(matching: predicate) {
                observer(.success($0 ?? []))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))

        let completed = Single.create { [store] observer in

            let predicate = store.predicateForCompletedReminders(
                withCompletionDateStarting: start, ending: end, calendars: calendars
            )

            store.fetchReminders(matching: predicate) {
                observer(.success($0 ?? []))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))

        return Single.zip(incomplete, completed).map { [dateProvider] in
            Array(
                Dictionary(grouping: $0 + $1, by: \.calendarItemIdentifier)
                    .compactMapValues {
                        $0.first.flatMap { EventModel(from: $0, dateProvider: dateProvider) }
                    }
                    .values
            )
        }
    }

    func createReminder(title: String, date: Date) -> Completable {

        Completable.create { [store, dateProvider] observer in
            do {
                guard let calendar = store.defaultCalendarForNewReminders() else {
                    throw .unexpected("Missing default calendar for reminders")
                }
                let reminder = EKReminder(eventStore: store)
                reminder.calendar = calendar
                reminder.title = title
                reminder.dueDateComponents = date.dateComponents(using: dateProvider)
                reminder.addAlarm(EKAlarm(absoluteDate: date))
                try store.save(reminder, commit: true)
                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func completeReminder(id: String, complete: Bool) -> Completable {

        Completable.create { [store] observer in
            do {
                guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                    throw .unexpected("🔥 Not a reminder")
                }
                reminder.isCompleted = complete
                try store.save(reminder, commit: true)
                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func rescheduleReminder(id: String, to date: Date) -> Completable {

        Completable.create { [store, dateProvider] observer in
            do {
                guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                    throw .unexpected("🔥 Not a reminder")
                }
                reminder.isCompleted = false
                reminder.dueDateComponents = date.dateComponents(using: dateProvider)
                reminder.alarms?.forEach(reminder.removeAlarm)
                reminder.addAlarm(EKAlarm(absoluteDate: date))
                try store.save(reminder, commit: true)
                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func changeEventStatus(id: String, date: Date, to status: EventStatus) -> Completable {

        Completable.create { [store] observer in

            let disposable = Disposables.create()

            do {
                let predicate = store.predicateForEvents(withStart: date, end: date + 1, calendars: nil)

                guard let event = store.events(matching: predicate).first(where: { $0.calendarItemIdentifier == id }) else {
                    throw .unexpected("🔥 Event not found")
                }

                guard let user = event.currentUser else {
                    throw .unexpected("🔥 User not found")
                }

                let new_status: EKParticipantStatus

                switch status {
                case .accepted:
                    new_status = .accepted
                case .maybe:
                    new_status = .tentative
                case .declined:
                    new_status = .declined
                default:
                    return disposable
                }

                guard user.participantStatus != new_status else {
                    observer(.completed)
                    return disposable
                }

                user.setParticipantStatus(new_status)

                // Alarms prevent recurrent events from saving; we get an error saying "Access Denied".
                // To fix that, we have to remove and re-add them after the event is detached ¯\_(ツ)_/¯

                guard event.hasRecurrenceRules, !event.isDetached, let alarms = event.alarms, !alarms.isEmpty else {
                    try store.save(event, span: .thisEvent)
                    observer(.completed)
                    return disposable
                }

                event.alarms?.forEach(event.removeAlarm)
                try store.save(event, span: .thisEvent)

                alarms.forEach {
                    event.addAlarm(EKAlarm(relativeOffset: $0.relativeOffset))
                }
                try store.save(event, span: .thisEvent)

                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}

private class EventStore: EKEventStore {

    override func requestAccess(to entityType: EKEntityType) async throws -> Bool {

        switch entityType {
        case .event:
            return try await requestFullAccessToEvents()
        case .reminder:
            return try await requestFullAccessToReminders()
        @unknown default:
            throw .unexpected("🔥 Unknown entity type: \(entityType)")
        }
    }

    func hasAccess(to entityType: EKEntityType) -> Bool {
        EventStore.authorizationStatus(for: entityType) == .fullAccess
    }
}

private enum PrivacyEntity: String {
    case calendars
    case reminders
}

private extension URL {

    static func privacySettings(for entity: PrivacyEntity) -> URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(entity.rawValue.ucfirst)")!
    }
}

private extension Strings.AccessRequired {

    static func message(for entity: PrivacyEntity) -> String {
        switch entity {
        case .calendars:
            return Strings.AccessRequired.calendars
        case .reminders:
            return Strings.AccessRequired.reminders
        }
    }
}

extension EKParticipant {

    func setParticipantStatus(_ status: EKParticipantStatus) {
        setValue(status.rawValue, forKey: "participantStatus")
    }
}

extension EKEvent {

    var currentUser: EKParticipant? {
        attendees?.first(where: \.isCurrentUser)
    }

    // Fix events that should be all-day but are not correctly reported as such (ex. Google's "Out of office")
    func shouldBeAllDay(_ dateProvider: DateProviding) -> Bool {
        guard !isAllDay else { return true }
        let range = DateRange(start: startDate, end: endDate, timeZone: timeZone, dateProvider: dateProvider)
        return !range.isSingleDay && range.startsMidnight && range.endsMidnight
    }
}

private extension Participant {

    init(from participant: EKParticipant, isOrganizer: Bool) {
        self.init(
            name: participant.name ?? participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: ""),
            status: .init(from: participant.participantStatus),
            isOrganizer: isOrganizer,
            isCurrentUser: participant.isCurrentUser
        )
    }
}

private extension EventStatus {

    init(from status: EKParticipantStatus?) {
        switch status {
        case .accepted:
            self = .accepted
        case .tentative:
            self = .maybe
        case .declined:
            self = .declined
        case .pending:
            self = .pending
        default:
            self = .unknown
        }
    }
}

private extension EKCalendar {

    var accountTitle: String {
        switch source.sourceType {
        case .local, .subscribed, .birthdays:
            Strings.Calendars.Source.others
        default:
            source.title
        }
    }

    // this is only populated from events
    var accountEmail: String? {
        try? safeValue(forKey: "selfIdentityEmail")
    }
}

private extension CalendarAccount {

    init(from calendar: EKCalendar) {
        self.init(title: calendar.accountTitle, email: calendar.accountEmail)
    }
}

private extension CalendarModel {

    init(from calendar: EKCalendar) {
        self.init(
            id: calendar.calendarIdentifier,
            account: .init(from: calendar),
            title: calendar.title,
            color: calendar.color,
            isSubscribed: calendar.isSubscribed || calendar.isDelegate
        )
    }
}

private extension EventType {

    init(from event: EKEvent) {
        self = event.birthdayContactIdentifier.isNotNil ? .birthday : .event(.init(from: event.currentUser?.participantStatus))
    }
}

private extension Array where Element == Participant {

    init(from event: EKEvent) {
        var participants = event.attendees ?? []
        if let organizer = event.organizer, !participants.contains(where: { $0.url == organizer.url }) {
            participants.append(organizer)
        }
        self.init(
            participants.map { .init(from: $0, isOrganizer: $0.url == event.organizer?.url) }
        )
    }
}

private extension Priority {

    /// 1-4 are considered "high," a priority of 5 is "medium," and priorities of 6-9 are "low"
    init?(from p: Int) {
        switch p {
        case 1...4:
            self = .high
        case 5:
            self = .medium
        case 6...9:
            self = .low
        default:
            return nil
        }
    }
}

private extension EventModel {

    init?(from event: EKEvent, dateProvider: DateProviding) {
        guard
            let calendar = event.calendar
        else { return nil }

        self.init(
            id: event.calendarItemIdentifier,
            externalId: event.calendarItemExternalIdentifier,
            start: event.startDate,
            end: event.endDate,
            title: event.title,
            location: event.location,
            coordinates: (event.structuredLocation?.geoLocation?.coordinate).map(Coordinates.init),
            notes: event.notes,
            url: event.url,
            isAllDay: event.shouldBeAllDay(dateProvider),
            type: .init(from: event),
            calendar: .init(from: calendar),
            participants: .init(from: event),
            timeZone: calendar.isSubscribed || calendar.isDelegate ? nil : event.timeZone,
            hasRecurrenceRules: event.hasRecurrenceRules || event.isDetached,
            priority: nil,
            attachments: event.attachments
        )
    }

    init?(from reminder: EKReminder, dateProvider: DateProviding) {
        guard 
            let calendar = reminder.calendar,
            let dueDateComponents = reminder.dueDateComponents,
            let date = dateProvider.calendar.date(from: dueDateComponents)
        else { return nil }

        self.init(
            id: reminder.calendarItemIdentifier,
            externalId: reminder.calendarItemExternalIdentifier,
            start: date,
            end: dateProvider.calendar.endOfDay(for: date),
            title: reminder.title,
            location: reminder.location, // doesn't work
            coordinates: nil,
            notes: reminder.notes,
            url: reminder.url, // doesn't work
            isAllDay: dueDateComponents.hour == nil,
            type: .reminder(completed: reminder.isCompleted),
            calendar: .init(from: calendar),
            participants: [],
            timeZone: calendar.isSubscribed || calendar.isDelegate ? nil : reminder.timeZone,
            hasRecurrenceRules: reminder.hasRecurrenceRules,
            priority: .init(from: reminder.priority),
            attachments: reminder.attachments // doesn't work
        )
    }
}

private extension EKCalendar {

    var isDelegate: Bool {
        source.isDelegate
    }
}

extension EKEntityType: @retroactive CustomStringConvertible {

    public var description: String {
        switch self {
        case .event:
            return "events"
        case .reminder:
            return "reminders"
        @unknown default:
            return "unknown"
        }
    }
}
