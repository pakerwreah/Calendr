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
    func completeReminder(id: String) -> Completable
    func rescheduleReminder(id: String, to: Date) -> Completable
    func changeEventStatus(id: String, date: Date, to: EventStatus) -> Completable
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let dateProvider: DateProviding
    private let workspace: WorkspaceServiceProviding
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter

    private let store = EventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>
    let changeObservable: Observable<Void>

    init(
        dateProvider: DateProviding,
        workspace: WorkspaceServiceProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {
        self.dateProvider = dateProvider
        self.workspace = workspace
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter

        (changeObservable, changeObserver) = PublishSubject.pipe(scheduler: MainScheduler.instance)

        requestAccess()
    }

    private func listenToStoreChanges() {

        notificationCenter.rx
            .notification(.EKEventStoreChanged, object: store)
            .void()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    @discardableResult
    private func openPrivacySettings(for entity: PrivacyEntity) -> Bool {

        guard !userDefaults.permissionSuppressed.contains(entity.rawValue) else {
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
            userDefaults.permissionSuppressed.append(entity.rawValue)
        }

        return false
    }

    private func requestAccess() {
        Task {
            listenToStoreChanges()

            let events = await requestAccess(to: .event)
            let reminders = await requestAccess(to: .reminder)

            DispatchQueue.main.async {
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

            let events = store.events(matching: predicate).map { EventModel(from: $0, dateProvider: dateProvider) }

            observer(.success(events))

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    private func fetchReminders(from start: Date, to end: Date, calendars: [EKCalendar]) -> Single<[EventModel]> {

        guard store.hasAccess(to: .reminder) else { return .just([]) }

        return Single.create { [store, dateProvider] observer in

            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: start, ending: end, calendars: calendars
            )

            store.fetchReminders(matching: predicate) {
                observer(.success($0?.compactMap { EventModel(from: $0, dateProvider: dateProvider) } ?? []))
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func completeReminder(id: String) -> Completable {

        Completable.create { [store] observer in

            let disposable = Disposables.create()

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer(.error(.unexpected("🔥 Not a reminder")))
                return disposable
            }

            do {
                reminder.isCompleted = true
                try store.save(reminder, commit: true)
                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func rescheduleReminder(id: String, to date: Date) -> Completable {

        Completable.create { [store, dateProvider] observer in

            let disposable = Disposables.create()

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer(.error(.unexpected("🔥 Not a reminder")))
                return disposable
            }

            do {
                reminder.dueDateComponents = date.dateComponents(dateProvider)
                reminder.alarms?.forEach(reminder.removeAlarm)
                reminder.addAlarm(EKAlarm(absoluteDate: date))
                try store.save(reminder, commit: true)
                observer(.completed)
            } catch {
                observer(.error(error))
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func changeEventStatus(id: String, date: Date, to status: EventStatus) -> Completable {

        Completable.create { [store] observer in

            let disposable = Disposables.create()

            let predicate = store.predicateForEvents(withStart: date, end: date + 1, calendars: nil)

            guard let event = store.events(matching: predicate).first(where: { $0.calendarItemIdentifier == id }) else {
                observer(.error(.unexpected("🔥 Event not found")))
                return disposable
            }

            guard
                let user = event.attendees?.first(where: \.isCurrentUser)
            else {
                observer(.error(.unexpected("🔥 User not found")))
                return disposable
            }

            do {
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

                if event.status != new_status {
                    user.setValue(new_status.rawValue, forKey: "participantStatus")
                    try store.save(event, span: .thisEvent)
                }

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

        guard #available(macOS 14.0, *) else {
            return try await super.requestAccess(to: entityType)
        }

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
        let status = EventStore.authorizationStatus(for: entityType)
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
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

extension EKEvent {

    var status: EKParticipantStatus {
        attendees?.first(where: \.isCurrentUser).map(\.participantStatus) ?? .unknown
    }

    // Fix events that should be all-day but are not correctly reported as such (ex. Google's "Out of office")
    func shouldBeAllDay(_ dateProvider: DateProviding) -> Bool {
        guard !isAllDay else { return true }
        let range = DateRange(start: startDate, end: endDate, dateProvider: dateProvider)
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

    init(from status: EKParticipantStatus) {
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

private extension CalendarModel {

    init(from calendar: EKCalendar) {
        self.init(
            id: calendar.calendarIdentifier,
            account: calendar.source.title,
            title: calendar.title,
            color: calendar.color
        )
    }
}

private extension EventType {

    init(from event: EKEvent) {
        self = event.birthdayContactIdentifier.isNotNil ? .birthday : .event(.init(from: event.status))
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

private extension EventModel {

    init(from event: EKEvent, dateProvider: DateProviding) {
        self.init(
            id: event.calendarItemIdentifier,
            start: event.startDate,
            end: event.endDate,
            title: event.title,
            location: event.location,
            notes: event.notes,
            url: event.url,
            isAllDay: event.shouldBeAllDay(dateProvider),
            type: .init(from: event),
            calendar: .init(from: event.calendar),
            participants: .init(from: event),
            timeZone: event.calendar.isSubscribed ? nil : event.timeZone,
            hasRecurrenceRules: event.hasRecurrenceRules
        )
    }

    init?(from reminder: EKReminder, dateProvider: DateProviding) {
        guard 
            let dueDateComponents = reminder.dueDateComponents,
            let date = dateProvider.calendar.date(from: dueDateComponents)
        else { return nil }
        
        self.init(
            id: reminder.calendarItemIdentifier,
            start: date,
            end: dateProvider.calendar.endOfDay(for: date),
            title: reminder.title,
            location: reminder.location, // doesn't work
            notes: reminder.notes,
            url: reminder.url, // doesn't work
            isAllDay: reminder.dueDateComponents!.hour == nil,
            type: .reminder,
            calendar: .init(from: reminder.calendar),
            participants: [],
            timeZone: reminder.calendar.isSubscribed ? nil : reminder.timeZone,
            hasRecurrenceRules: reminder.hasRecurrenceRules
        )
    }
}

extension EKEntityType: CustomStringConvertible {

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

private extension Date {

    func dateComponents(_ dateProvider: DateProviding) -> DateComponents {
        dateProvider.calendar.dateComponents(in: dateProvider.calendar.timeZone, from: self)
    }
}
