//
//  MockCalendarSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockCalendarSettings: CalendarSettings {

    let calendarScaling: Observable<Double>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>
    let firstWeekday: Observable<Int>
    let highlightedWeekdays: Observable<[Int]>
    let weekCount: Observable<Int>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let dateHoverOption: Observable<Bool>
    let eventDotsStyle: Observable<EventDotsStyle>
    let calendarAppViewMode: Observable<CalendarViewMode>
    let defaultCalendarApp: Observable<CalendarApp>
    let futureEventsDays: Observable<Int>

    init(
        calendarScaling: Double = 1,
        textScaling: Double = 1,
        calendarTextScaling: Double = 1,
        firstWeekday: Int = 1,
        highlightedWeekdays: [Int] = [0, 6],
        showWeekNumbers: Bool = true,
        weekCount: Int = 6,
        eventDotsStyle: EventDotsStyle = .multiple,
    ) {
        self.calendarScaling = .just(calendarScaling)
        self.textScaling = .just(textScaling)
        self.calendarTextScaling = .just(calendarTextScaling)
        self.firstWeekday = .just(firstWeekday)
        self.highlightedWeekdays = .just(highlightedWeekdays)
        self.weekCount = .just(weekCount)
        self.showWeekNumbers = .just(showWeekNumbers)
        self.preserveSelectedDate = .just(false)
        self.showDeclinedEvents = .just(false)
        self.dateHoverOption = .just(false)
        self.eventDotsStyle = .just(eventDotsStyle)
        self.calendarAppViewMode = .just(.month)
        self.defaultCalendarApp = .just(.calendar)
        self.futureEventsDays = .just(0)
    }
}

#endif
