//
//  MockCalendarSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockCalendarSettings: CalendarSettings {

    let firstWeekday: Observable<Int>
    let firstWeekdayObserver: AnyObserver<Int>

    let highlightedWeekdays: Observable<[Int]>
    let highlightedWeekdaysObserver: AnyObserver<[Int]>

    let showWeekNumbers: Observable<Bool>
    let toggleWeekNumbers: AnyObserver<Bool>

    let showDeclinedEvents: Observable<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>

    let preserveSelectedDate: Observable<Bool>

    let calendarScaling: Observable<Double>
    let textScaling: Observable<Double>

    init() {
        (firstWeekday, firstWeekdayObserver) = BehaviorSubject.pipe(value: 1)
        (highlightedWeekdays, highlightedWeekdaysObserver) = BehaviorSubject.pipe(value: [0, 6])
        (showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: false)
        (showDeclinedEvents, toggleDeclinedEvents) = BehaviorSubject.pipe(value: false)
        preserveSelectedDate = .just(false)
        calendarScaling = .just(1)
        textScaling = .just(1)
    }
}
