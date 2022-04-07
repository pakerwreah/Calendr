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
    let calendarScaling: Observable<Double>

    init(showWeekNumbers: Bool = true) {
        self.showWeekNumbers = .just(showWeekNumbers)
        self.calendarScaling = .just(1)
    }
}

#endif
