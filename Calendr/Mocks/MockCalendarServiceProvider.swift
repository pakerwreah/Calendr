//
//  MockCalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

class MockCalendarServiceProvider: CalendarServiceProviding {

    let m_events: [EventModel]
    let m_calendars: [CalendarModel]
    let dateProvider: DateProviding

    private let changeObserver: AnyObserver<Void>
    let changeObservable: Observable<Void>

    private var calendar: Calendar { dateProvider.calendar }

    init(events: [EventModel] = [], calendars: [CalendarModel] = [], dateProvider: DateProviding = MockDateProvider()) {

        self.m_events = events
        self.m_calendars = calendars
        self.dateProvider = dateProvider

        (changeObservable, changeObserver) = PublishSubject.pipe()
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Single<[EventModel]> {
        .just(
            m_events
                .filter { $0.calendar.id.isEmpty || calendars.contains($0.calendar.id) }
                .filter { calendar.isDay($0.start, inDays: (start, end)) || calendar.isDay($0.end, inDays: (start, end)) }
        )
    }

    func calendars() -> Single<[CalendarModel]> { .just(m_calendars) }

    func createReminder(title: String, date: Date) -> Completable { .empty() }

    func completeReminder(id: String, complete: Bool) -> Completable { .empty() }

    func rescheduleReminder(id: String, to: Date) -> Completable { .empty() }

    func changeEventStatus(id: String, date: Date, to: EventStatus) -> Completable { .empty() }

    func requestAccess() { changeObserver.onNext(()) }
}

#endif
