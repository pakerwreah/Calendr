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

    init(
        isPresented: Bool = false,
        preserveSelectedDate: Bool = false,
        calendarAppViewMode: CalendarViewMode = .month,

    ) {
        (self.isPresented, toggleIsPresented) = BehaviorSubject.pipe(value: isPresented)
        (self.preserveSelectedDate, togglePreserveSelectedDate) = BehaviorSubject.pipe(value: preserveSelectedDate)
        (self.calendarAppViewMode, calendarAppViewModeObserver) = BehaviorSubject.pipe(value: calendarAppViewMode)
    }
}

#endif
