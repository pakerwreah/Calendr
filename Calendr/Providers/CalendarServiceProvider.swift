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

    func calendars() -> Observable<[CalendarModel]>
    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]>
    func event(_ identifier: String) -> EventDetailsModel?
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let store = EKEventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>

    let changeObservable: Observable<Void>

    init() {
        (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

        NotificationCenter.default.rx
            .notification(.EKEventStoreChanged, object: store)
            .toVoid()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    func requestAccess() {
        if EKEventStore.authorizationStatus(for: .event) == .authorized {
            changeObserver.onNext(())
        } else {
            store.requestAccess(to: .event) { granted, error in

                if let error = error {
                    print(error.localizedDescription)
                } else if granted {
                    print("Access granted!")
                } else {
                    print("Access not granted!")
                }
            }
        }
    }

    func calendars() -> Observable<[CalendarModel]> {

        Observable.create { [store] observer in
            let calendars = store
                .calendars(for: .event)
                .map(CalendarModel.init(from:))

            observer.onNext(calendars)

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]> {

        Observable.create { [store] observer in

            let predicate = store.predicateForEvents(
                withStart: start, end: end,
                calendars: calendars.compactMap(store.calendar(withIdentifier:))
            )

            let events = store.events(matching: predicate)
                .filter { $0.status != .declined }
                .map(EventModel.init(from:))

            observer.onNext(events)

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }

    func event(_ identifier: String) -> EventDetailsModel? {
        let group = DispatchGroup()
        group.enter()

        var details: EventDetailsModel?
        // I have no idea why I have to request authorization again
        store.requestAccess(to: .event) { [store] _, _ in
            details = store.event(withIdentifier: identifier)
            group.leave()
        }
        group.wait()

        return details
    }
}

extension EKEvent {

    var status: EKParticipantStatus {
        attendees?.first(where: \.isCurrentUser).map(\.participantStatus) ?? .unknown
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
            isPending: event.status == .pending,
            isBirthday: event.birthdayContactIdentifier.isNotNil,
            calendar: .init(from: event.calendar)
        )
    }
}

typealias EventDetailsModel = EKEvent
