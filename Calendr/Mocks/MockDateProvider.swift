//
//  MockDateProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

class MockDateProvider: DateProviding {
    var m_calendar: Calendar
    var calendar: Calendar { m_calendar }
    var now: Date

    let calendarUpdated: Observable<Calendar>
    private let calendarObserver: AnyObserver<Calendar>

    init(
        calendar: Calendar = .gregorian,
        now: Date = .make(year: 2021, month: 1, day: 1)
    ) {
        self.m_calendar = calendar
        self.now = now
        (calendarUpdated, calendarObserver) = PublishSubject.pipe()
    }

    func add(_ value: Int, _ component: Calendar.Component) {
        now = calendar.date(byAdding: component, value: value, to: now)!
    }

    func notifyCalendarUpdated() {
        calendarObserver.onNext(calendar)
    }
}

#endif
