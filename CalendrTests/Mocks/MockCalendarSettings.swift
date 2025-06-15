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

    let weekCount: Observable<Int>
    let weekCountObserver: AnyObserver<Int>

    let showWeekNumbers: Observable<Bool>
    let toggleWeekNumbers: AnyObserver<Bool>

    let showDeclinedEvents: Observable<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>

    let dateHoverOption: Observable<Bool>
    let toggleDateHoverOption: AnyObserver<Bool>

    let preserveSelectedDate: Observable<Bool>

    let calendarAppViewMode: Observable<CalendarViewMode>

    let calendarScaling: Observable<Double>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>

    let defaultCalendarApp: Observable<CalendarApp>

    init() {
        (firstWeekday, firstWeekdayObserver) = BehaviorSubject.pipe(value: 1)
        (highlightedWeekdays, highlightedWeekdaysObserver) = BehaviorSubject.pipe(value: [0, 6])
        (showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: false)
        (weekCount, weekCountObserver) = BehaviorSubject.pipe(value: 6)
        (showDeclinedEvents, toggleDeclinedEvents) = BehaviorSubject.pipe(value: false)
        (dateHoverOption, toggleDateHoverOption) = BehaviorSubject.pipe(value: false)
        preserveSelectedDate = .just(false)
        calendarAppViewMode = .just(.month)
        calendarScaling = .just(1)
        textScaling = .just(1)
        calendarTextScaling = .just(1)
        defaultCalendarApp = .just(.calendar)
    }
}
