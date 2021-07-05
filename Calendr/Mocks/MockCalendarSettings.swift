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

    init(showWeekNumbers: Bool = true) {
        self.showWeekNumbers = .just(showWeekNumbers)
    }
}

#endif
