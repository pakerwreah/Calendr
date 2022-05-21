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
    func changeEventStatus(id: String, to: EventStatus) -> Observable<Void>
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let store = EKEventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>

    let changeObservable: Observable<Void>

    init(notificationCenter: NotificationCenter) {

        (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

        notificationCenter.rx
            .notification(.EKEventStoreChanged, object: store)
            .void()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    func requestAccess() {
        requestAccess(for: .event) {
            self.requestAccess(for: .reminder)
        }
    }

    private func requestAccess(for type: EKEntityType, completion: (() -> Void)? = nil) {

        if EKEventStore.authorizationStatus(for: type) == .authorized {
            if let completion = completion {
                completion()
            } else {
                changeObserver.onNext(())
            }
        } else {
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
    }

    func calendars() -> Observable<[CalendarModel]> {

        Observable.create { [store] observer in

            observer.onNext(
                (store.calendars(for: .event) + store.calendars(for: .reminder)).map(CalendarModel.init(from:))
            )

            observer.onCompleted()

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]> {

        let calendars = calendars.compactMap(store.calendar(withIdentifier:))

        return Observable.zip(
            fetchEvents(from: start, to: end, calendars: calendars),
            fetchReminders(from: start, to: end, calendars: calendars)
        )
        .map(+)
    }

    private func fetchEvents(from start: Date, to end: Date, calendars: [EKCalendar]) -> Observable<[EventModel]> {

        Observable.create { [store] observer in

            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)

            let events = store.events(matching: predicate)
                .filter { $0.status != .declined }
                .map(EventModel.init(from:))

            observer.onNext(events)
            observer.onCompleted()

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func fetchReminders(from start: Date, to end: Date, calendars: [EKCalendar]) -> Observable<[EventModel]> {

        Observable.create { [store] observer in

            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: start, ending: end, calendars: calendars
            )

            store.fetchReminders(matching: predicate) {
                observer.onNext($0?.map(EventModel.init(from:)) ?? [])
                observer.onCompleted()
            }

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func completeReminder(id: String) -> Observable<Void> {

        Observable.create { [store] observer in

            let disposable = Disposables.create()

            defer { observer.onCompleted() }

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer.onError(.unexpected("🔥 Not a reminder"))
                return disposable
            }

            do {
                reminder.isCompleted = true
                try store.save(reminder, commit: true)
                observer.onNext(())
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func rescheduleReminder(id: String, to date: Date) -> Observable<Void> {

        Observable.create { [store] observer in

            let disposable = Disposables.create()

            defer { observer.onCompleted() }

            guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
                observer.onError(.unexpected("🔥 Not a reminder"))
                return disposable
            }

            do {
                reminder.dueDateComponents = date.dateComponents
                reminder.alarms?.forEach(reminder.removeAlarm)
                reminder.addAlarm(EKAlarm(absoluteDate: date))
                try store.save(reminder, commit: true)
                observer.onNext(())
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func changeEventStatus(id: String, to status: EventStatus) -> Observable<Void> {

        Observable.create { [store] observer in

            let disposable = Disposables.create()

            defer { observer.onCompleted() }

            guard let event = store.event(withIdentifier: id) else {
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
                switch status {
                case .accepted:
                    user.setValue(EKParticipantStatus.accepted.rawValue, forKey: "participantStatus")
                case .maybe:
                    user.setValue(EKParticipantStatus.tentative.rawValue, forKey: "participantStatus")
                case .declined:
                    user.setValue(EKParticipantStatus.declined.rawValue, forKey: "participantStatus")
                default:
                    return disposable
                }

                try store.save(event, span: .thisEvent)

                observer.onNext(())
            } catch {
                observer.onError(error)
            }

            return disposable
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}

extension EKEvent {

    var status: EKParticipantStatus {
        attendees?.first(where: \.isCurrentUser).map(\.participantStatus) ?? .unknown
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
            identifier: calendar.calendarIdentifier,
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
        let attendees: [EKParticipant] = (event.attendees ?? []) + (event.organizer.map { [$0] } ?? [])
        self.init(
            Set(attendees.map { .init(from: $0, isOrganizer: $0.url == event.organizer?.url) })
        )
    }
}

private extension EventModel {

    init(from event: EKEvent) {
        self.init(
            id: event.eventIdentifier,
            start: event.startDate,
            end: event.endDate,
            title: event.title,
            location: event.location,
            notes: event.notes,
            url: event.url,
            isAllDay: event.isAllDay,
            type: .init(from: event),
            calendar: .init(from: event.calendar),
            participants: .init(from: event)
        )
    }

    init(from reminder: EKReminder) {
        self.init(
            id: reminder.calendarItemIdentifier,
            start: reminder.dueDateComponents!.date,
            end: reminder.dueDateComponents!.endOfDay,
            title: reminder.title,
            location: reminder.location, // doesn't work
            notes: reminder.notes,
            url: reminder.url, // doesn't work
            isAllDay: reminder.dueDateComponents!.hour == nil,
            type: .reminder,
            calendar: .init(from: reminder.calendar),
            participants: []
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

private extension DateComponents {

    var date: Date {
        Calendar.autoupdatingCurrent.date(from: self)!
    }

    var endOfDay: Date {
        Calendar.autoupdatingCurrent.endOfDay(for: date)
    }
}

private extension Date {

    var dateComponents: DateComponents {
        Calendar.autoupdatingCurrent.dateComponents(in: .autoupdatingCurrent, from: self)
    }
}

private struct UnexpectedError: LocalizedError {

    let message: String

    var errorDescription: String? { message }
}

private extension Error where Self == UnexpectedError {

    static func unexpected(_ message: String) -> Self { .init(message: message) }
}
