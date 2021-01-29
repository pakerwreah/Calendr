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
                .map {
                    ($0, $0.attendees?.first(where: \.isCurrentUser).map(\.participantStatus))
                }
                .filter {
                    $1 != .declined
                }
                .map { event, status in
                    EventModel(
                        start: event.startDate,
                        end: event.endDate,
                        isAllDay: event.isAllDay,
                        title: event.title,
                        location: event.location,
                        notes: event.notes,
                        url: event.url,
                        isPending: status == .pending,
                        calendar: CalendarModel(from: event.calendar)
                    )
                }

            observer.onNext(events)

            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}

private extension CalendarModel {
    init(from calendar: EKCalendar) {
        self.init(
            identifier: calendar.calendarIdentifier,
            account: calendar.source.title,
            title: calendar.title,
            color: calendar.cgColor
        )
    }
}
