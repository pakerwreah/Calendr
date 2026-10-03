//
//  MockMainViewSettings.swift
//  Calendr
//
//  Created by Paker on 03/10/2026.
//

#if DEBUG

import RxSwift

class MockMainViewSettings: MainViewSettings {

    let isPresented: Observable<Bool>
    let toggleIsPresented: AnyObserver<Bool>

    let preserveSelectedDate: Observable<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>

    let calendarAppViewMode: Observable<CalendarViewMode>
    let calendarAppViewModeObserver: AnyObserver<CalendarViewMode>

    let showWeekNumbers: Observable<Bool>
    let toggleWeekNumbers: AnyObserver<Bool>

    let showDeclinedEvents: Observable<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>

    init(
        isPresented: Bool = false,
        preserveSelectedDate: Bool = false,
        calendarAppViewMode: CalendarViewMode = .month,
        showWeekNumbers: Bool = false,
        showDeclinedEvents: Bool = false,

    ) {
        (self.isPresented, toggleIsPresented) = BehaviorSubject.pipe(value: isPresented)
        (self.preserveSelectedDate, togglePreserveSelectedDate) = BehaviorSubject.pipe(value: preserveSelectedDate)
        (self.calendarAppViewMode, calendarAppViewModeObserver) = BehaviorSubject.pipe(value: calendarAppViewMode)
        (self.showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: showWeekNumbers)
        (self.showDeclinedEvents, toggleDeclinedEvents) = BehaviorSubject.pipe(value: showDeclinedEvents)
    }
}

#endif
