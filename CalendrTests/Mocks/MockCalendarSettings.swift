//
//  MockCalendarSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockCalendarSettings: CalendarSettings {

    let toggleWeekNumbers: AnyObserver<Bool>
    let showWeekNumbers: Observable<Bool>
    let calendarScaling: Observable<Double>

    init() {
        (showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: false)
        calendarScaling = .just(1)
    }
}
