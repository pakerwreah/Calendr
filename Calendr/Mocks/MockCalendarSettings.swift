//
//  MockCalendarSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

struct MockCalendarSettings: CalendarSettings {

    let calendarScaling: Observable<Double>
    let highlightedWeekdays: Observable<[Int]>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>

    init(calendarScaling: Double = 1, highlightedWeekdays: [Int] = [0, 6], showWeekNumbers: Bool = true) {
        self.calendarScaling = .just(calendarScaling)
        self.highlightedWeekdays = .just(highlightedWeekdays)
        self.showWeekNumbers = .just(showWeekNumbers)
        self.preserveSelectedDate = .just(false)
        self.showDeclinedEvents = .just(false)
    }
}

#endif
