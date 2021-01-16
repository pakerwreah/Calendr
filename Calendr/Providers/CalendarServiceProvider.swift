//
//  CalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import RxSwift
import EventKit

protocol CalendarServiceProviding {
    var authObservable: Observable<Void> { get }
    var changeObservable: Observable<Void> { get }

    func calendars() -> [CalendarModel]
    func events(from start: Date, to end: Date, calendars: [String]) -> [EventModel]
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let store = EKEventStore()

    private let disposeBag = DisposeBag()

    private let authObserver: AnyObserver<Bool>
    private let changeObserver: AnyObserver<Void>

    let authObservable: Observable<Void>
    let changeObservable: Observable<Void>

    init() {
        (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

        let authSubject = BehaviorSubject<Bool>(value: false)
        authObservable = authSubject.matching(true).toVoid()
        authObserver = authSubject.asObserver()

        NotificationCenter.default.rx
            .notification(.EKEventStoreChanged, object: store)
            .toVoid()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    func requestAccess() {
        if EKEventStore.authorizationStatus(for: .event) == .authorized {
            authObserver.onNext(true)
            changeObserver.onNext(())
        } else {
            store.requestAccess(to: .event) { [authObserver] granted, error in

                if let error = error {
                    print(error.localizedDescription)
                } else if granted {
                    print("Access granted!")
                    authObserver.onNext(true)
                } else {
                    print("Access not granted!")
                }
            }
        }
    }

    func calendars() -> [CalendarModel] {

        store.calendars(for: .event).map { calendar in
            CalendarModel(from: calendar)
        }
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> [EventModel] {

        let predicate = store.predicateForEvents(
            withStart: start, end: end,
            calendars: calendars.compactMap(store.calendar(withIdentifier:))
        )

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
            account: calendar.source.title,
            title: calendar.title,
            color: calendar.cgColor
        )
    }
}
