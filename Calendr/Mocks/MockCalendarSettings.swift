//
//  MockCalendarSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockCalendarSettings: CalendarSettings {

    let futureEventsDays: Observable<Int>
    let futureEventsDaysObserver: AnyObserver<Int>

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

    let showAllDayEvents: Observable<Bool>
    let toggleAllDayEvents: AnyObserver<Bool>

    let dateHoverOption: Observable<Bool>
    let toggleDateHoverOption: AnyObserver<Bool>

    let eventDotsStyle: Observable<EventDotsStyle>
    let eventDotsStyleObserver: AnyObserver<EventDotsStyle>

    let showMonthOutline: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>
    let calendarAppViewMode: Observable<CalendarViewMode>
    let defaultCalendarApp: Observable<CalendarApp>

    let calendarScaling: Observable<Double>
    let calendarScalingObserver: AnyObserver<Double>

    let calendarTextScaling: Observable<Double>
    let calendarTextScalingObserver: AnyObserver<Double>

    let textScaling: Observable<Double>
    let textScalingObserver: AnyObserver<Double>

    init(
        calendarScaling: Double = 1,
        textScaling: Double = 1,
        calendarTextScaling: Double = 1,
        firstWeekday: Int = 1,
        highlightedWeekdays: [Int] = [0, 6],
        showMonthOutline: Bool = false,
        showWeekNumbers: Bool = false,
        weekCount: Int = 6,
        eventDotsStyle: EventDotsStyle = .multiple,
        showDeclinedEvents: Bool = false,
        showAllDayEvents: Bool = true,
        dateHoverOption: Bool = false,
        futureEventsDays: Int = 0,
        preserveSelectedDate: Bool = false
    ) {
        (self.futureEventsDays, futureEventsDaysObserver) = BehaviorSubject.pipe(value: futureEventsDays)
        (self.firstWeekday, firstWeekdayObserver) = BehaviorSubject.pipe(value: firstWeekday)
        (self.highlightedWeekdays, highlightedWeekdaysObserver) = BehaviorSubject.pipe(value: highlightedWeekdays)
        (self.showWeekNumbers, toggleWeekNumbers) = BehaviorSubject.pipe(value: showWeekNumbers)
        (self.weekCount, weekCountObserver) = BehaviorSubject.pipe(value: weekCount)
        (self.showDeclinedEvents, toggleDeclinedEvents) = BehaviorSubject.pipe(value: showDeclinedEvents)
        (self.showAllDayEvents, toggleAllDayEvents) = BehaviorSubject.pipe(value: showAllDayEvents)
        (self.dateHoverOption, toggleDateHoverOption) = BehaviorSubject.pipe(value: dateHoverOption)
        (self.eventDotsStyle, eventDotsStyleObserver) = BehaviorSubject.pipe(value: eventDotsStyle)
        (self.calendarScaling, calendarScalingObserver) = BehaviorSubject.pipe(value: calendarScaling)
        (self.calendarTextScaling, calendarTextScalingObserver) = BehaviorSubject.pipe(value: calendarTextScaling)
        (self.textScaling, textScalingObserver) = BehaviorSubject.pipe(value: textScaling)
        (self.preserveSelectedDate, togglePreserveSelectedDate) = BehaviorSubject.pipe(value: preserveSelectedDate)

        self.showMonthOutline = .just(showMonthOutline)
        calendarAppViewMode = .just(.month)
        defaultCalendarApp = .just(.calendar)
    }
}

#endif
