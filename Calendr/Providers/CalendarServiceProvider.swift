//
//  CalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import RxSwift
import EventKit

protocol CalendarServiceProviding {

    var changeObservable: Observable<Void> { get }

    func requestAccess()
    func calendars() -> Observable<[CalendarModel]>
    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]>
    func completeReminder(id: String) -> Observable<Void>
    func rescheduleReminder(id: String, to: Date) -> Observable<Void>
    func changeEventStatus(id: String, date: Date, to: EventStatus) -> Observable<Void>
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let dateProvider: DateProviding

    private let store = EventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>

    let changeObservable: Observable<Void>

    init(dateProvider: DateProviding, notificationCenter: NotificationCenter) {

        self.dateProvider = dateProvider

        (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

        notificationCenter.rx
            .notification(.EKEventStoreChanged, object: store)
            .void()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    func requestAccess() {
        requestAccess(for: .event) {
            self.requestAccess(for: .reminder) {
                DispatchQueue.main.async {
                    self.changeObserver.onNext(())
                }
            }
        }
    }

    private func requestAccess(for type: EKEntityType, completion: (() -> Void)? = nil) {

        store.requestAccess(to: type) { granted, error in

            if let error = error {
                print(error.localizedDescription)
            } else if granted {
                print("Access granted for \(type)!")
            } else {
                print("Access denied for \(type)!")
            }

            completion?()
        }
    }

    private func storeCalendars() -> [EKCalendar] {
        store.calendars(for: .event) + store.calendars(for: .reminder)
    }

    func calendars() -> Observable<[CalendarModel]> {

        Observable.create { [weak self] observer in

            if let self {
                observer.onNext(storeCalendars().map(CalendarModel.init(from:)))
            }
            observer.onCompleted()

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]> {

        let calendars = storeCalendars().filter { calendars.contains($0.calendarIdentifier) }

        return Observable.zip(
            fetchEvents(from: start, to: end, calendars: calendars),
            fetchReminders(from: start, to: end, calendars: calendars)
        )
        .map(+)
    }

    private func fetchEvents(from start: Date, to end: Date, calendars: [EKCalendar]) -> Observable<[EventModel]> {

        guard store.hasAccess(to: .event) else { return .just([]) }

        return Observable.create { [store, dateProvider] observer in

            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)

            let events = store.events(matching: predicate).map { EventModel(from: $0, dateProvider: dateProvider) }

            observer.onNext(events)
            observer.onCompleted()

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    private func fetchReminders(from start: Date, to end: Date, calendars: [EKCalendar]) -> Observable<[EventModel]> {

        guard store.hasAccess(to: .reminder) else { return .just([]) }

        return Observable.create { [store, dateProvider] observer in

            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: start, ending: end, calendars: calendars
            )

            store.fetchReminders(matching: predicate) {
                observer.onNext($0?.compactMap { EventModel(from: $0, dateProvider: dateProvider) } ?? [])
                observer.onCompleted()
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func completeReminder(id: String) -> Observable<Void> {

        Observable.create { [store] observer in

            let disposable = Disposables.create()

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer.onError(.unexpected("🔥 Not a reminder"))
                return disposable
            }

            do {
                reminder.isCompleted = true
                try store.save(reminder, commit: true)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func rescheduleReminder(id: String, to date: Date) -> Observable<Void> {

        Observable.create { [store, dateProvider] observer in

            let disposable = Disposables.create()

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer.onError(.unexpected("🔥 Not a reminder"))
                return disposable
            }

            do {
                reminder.dueDateComponents = date.dateComponents(dateProvider)
                reminder.alarms?.forEach(reminder.removeAlarm)
                reminder.addAlarm(EKAlarm(absoluteDate: date))
                try store.save(reminder, commit: true)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func changeEventStatus(id: String, date: Date, to status: EventStatus) -> Observable<Void> {

        Observable.create { [store] observer in

            let disposable = Disposables.create()

            let predicate = store.predicateForEvents(withStart: date, end: date + 1, calendars: nil)

            guard let event = store.events(matching: predicate).first(where: { $0.calendarItemIdentifier == id }) else {
                observer.onError(.unexpected("🔥 Event not found"))
                return disposable
            }

            guard
                let user = event.attendees?.first(where: \.isCurrentUser)
            else {
                observer.onError(.unexpected("🔥 User not found"))
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

                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}

private class EventStore: EKEventStore {

    override func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {

        guard #available(macOS 14.0, *) else {
            return super.requestAccess(to: entityType, completion: completion)
        }

        switch entityType {
        case .event:
            requestFullAccessToEvents(completion: completion)
        case .reminder:
            requestFullAccessToReminders(completion: completion)
        @unknown default:
            completion(false, .unexpected("🔥 Unknown entity type: \(entityType)"))
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
