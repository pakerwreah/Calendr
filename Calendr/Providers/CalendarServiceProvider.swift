//
//  CalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import RxSwift
import EventKit

protocol CalendarServiceProviding {
    var calendars: [CalendarModel] { get }
    var changeObservable: Observable<Void> { get }

    func events(from start: Date, to end: Date) -> [EventModel]
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

    var calendars: [CalendarModel] {

        store.calendars(for: .event).map { cal in
            CalendarModel(from: cal)
        }
    }

    func events(from start: Date, to end: Date) -> [EventModel] {

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)

        return store.events(matching: predicate).map { event in
            EventModel(
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay,
                title: event.title,
                location: event.location,
                notes: event.notes,
                url: event.url,
                calendar: CalendarModel(from: event.calendar)
            )
        }
    }
}

private extension CalendarModel {
    init(from calendar: EKCalendar) {
        self.init(
            identifier: calendar.calendarIdentifier,
            title: calendar.title,
            color: calendar.cgColor
        )
    }
}
