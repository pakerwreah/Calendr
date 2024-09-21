//
//  MockCalendarSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockCalendarSettings: CalendarSettings {

    let calendarScaling: Observable<Double>
    let textScaling: Observable<Double>
    let firstWeekday: Observable<Int>
    let highlightedWeekdays: Observable<[Int]>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>

    init(
        calendarScaling: Double = 1,
        textScaling: Double = 1,
        firstWeekday: Int = 1,
        highlightedWeekdays: [Int] = [0, 6],
        showWeekNumbers: Bool = true
    ) {
        self.calendarScaling = .just(calendarScaling)
        self.textScaling = .just(textScaling)
        self.firstWeekday = .just(firstWeekday)
        self.highlightedWeekdays = .just(highlightedWeekdays)
        self.showWeekNumbers = .just(showWeekNumbers)
        self.preserveSelectedDate = .just(false)
        self.showDeclinedEvents = .just(false)
    }
}

#endif
