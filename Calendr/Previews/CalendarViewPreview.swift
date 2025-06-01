//
//  CalendarViewPreview.swift
//  Calendr
//
//  Created by Paker on 04/07/2021.
//

#if DEBUG

import SwiftUI
import RxSwift

struct CalendarViewPreview: PreviewProvider {

    static let dateProvider = MockDateProvider()
    static let calendarService = MockCalendarServiceProvider(events: events, dateProvider: dateProvider)
    static let settings = MockCalendarSettings(
        calendarScaling: 1.3,
        firstWeekday: 1,
        highlightedWeekdays: [0, 1, 4, 6],
        showWeekNumbers: true
    )
    static let hovered = BehaviorSubject<Date?>(value: .random(from: dateProvider))
    static let selected = BehaviorSubject<Date>(value: .random(inMonth: dateProvider))

    static let events: [EventModel] = (0..<30).map { _ in
        let date: Date = .random(from: dateProvider)
        return .make(start: date, end: date, calendar: .make(color: .random()))
    }

    static var previews: some View {
        CalendarView(
            viewModel: CalendarViewModel(
                searchObservable: .just(""),
                dateObservable: selected,
                hoverObservable: hovered,
                keyboardModifiers: .just([]),
                enabledCalendars: .empty(),
                calendarService: calendarService,
                dateProvider: dateProvider,
                settings: settings,
                scheduler: MainScheduler.instance
            ),
            hoverObserver: hovered.asObserver(),
            clickObserver: selected.asObserver(),
            doubleClickObserver: .dummy()
        )
        .preview()
        .fixedSize()
    }
}

private extension Date {

    static func random(inMonth dateProvider: DateProviding) -> Date {
        let calendar = dateProvider.calendar
        let date = dateProvider.now
        var components = calendar.dateComponents(in: calendar.timeZone, from: date)
        components.day = calendar.range(of: .day, in: .month, for: date)!.randomElement()
        return calendar.date(from: components)!
    }

    static func random(from dateProvider: DateProviding) -> Date {
        dateProvider.calendar.date(byAdding: .day, value: .random(in: 0..<42), to: dateProvider.now)!
    }
}

private extension NSColor {

    static func random() -> NSColor {
        [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple].randomElement()!
    }
}

#endif
