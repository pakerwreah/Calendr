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
    func events(from start: Date, to end: Date) -> [EventModel]
    var changeObservable: Observable<Void> { get }
    var isAuthorized: Bool { get }
}

class CalendarServiceProvider: CalendarServiceProviding {

    private let store = EKEventStore()

    private let disposeBag = DisposeBag()

    private let changeObserver: AnyObserver<Void>

    let changeObservable: Observable<Void>

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .authorized
    }

    init() {
        (changeObserver, changeObservable) = PublishSubject<Void>.pipe()

        NotificationCenter.default.rx
            .notification(.EKEventStoreChanged, object: store)
            .toVoid()
            .bind(to: changeObserver)
            .disposed(by: disposeBag)
    }

    func requestAccess() {
        if isAuthorized {
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
            // FIXME: Create settings screen to select calendars
            CalendarModel(from: cal, isSelected: !cal.title.contains("WR"))
        }
    }

    func events(from start: Date, to end: Date) -> [EventModel] {

        let selected = calendars
            .filter(\.isSelected)
            .map(\.identifier)
            .compactMap(store.calendar(withIdentifier:))

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: selected)

        return store.events(matching: predicate).map { event in
            EventModel(
                start: event.startDate,
                end: event.endDate,
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
    init(from calendar: EKCalendar, isSelected: Bool = true) {
        self.init(
            identifier: calendar.calendarIdentifier,
            title: calendar.title,
            color: calendar.cgColor,
            isSelected: isSelected
        )
    }
}
