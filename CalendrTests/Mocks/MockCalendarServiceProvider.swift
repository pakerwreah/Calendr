//
//  MockCalendarServiceProvider.swift
//  CalendrTests
//
//  Created by Paker on 11/03/2021.
//

import RxSwift
@testable import Calendr

typealias EventsArgs = (start: Date, end: Date, calendars: [String])

class MockCalendarServiceProvider: CalendarServiceProviding {

    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()
    let (spyEventsObservable, spyEventsObserver) = PublishSubject<EventsArgs>.pipe()

    var m_calendars: [CalendarModel] = []
    var m_events: [EventModel] = []

    func calendars() -> Observable<[CalendarModel]> {
        return .just(m_calendars)
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]> {
        spyEventsObserver.onNext((start: start, end: end, calendars: calendars))
        return .just(m_events)
    }
}
