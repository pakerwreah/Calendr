//
//  MockCalendarSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

struct MockCalendarSettings: CalendarSettings {

    let showWeekNumbers: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let calendarScaling: Observable<Double>

    init(showWeekNumbers: Bool = true, calendarScaling: Double = 1) {
        self.showWeekNumbers = .just(showWeekNumbers)
        self.preserveSelectedDate = .just(false)
        self.showDeclinedEvents = .just(false)
        self.calendarScaling = .just(calendarScaling)
    }
}

#endif
