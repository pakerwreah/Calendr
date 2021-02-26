//
//  MockCalendarSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockCalendarSettings: CalendarSettings {

    var toggleWeekNumbers: AnyObserver<Bool>
    var showWeekNumbers: Observable<Bool>

    init() {
        (showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: false)
    }
}
