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
    static let calendarService = MockCalendarServiceProvider(dateProvider: dateProvider)
    static let settings = MockCalendarSettings()
    static let notificationCenter = NotificationCenter()

    static let hovered = BehaviorSubject<Date?>(value: .random(from: dateProvider))
    static let selected = BehaviorSubject<Date>(value: .random(inMonth: dateProvider))

    static func make(_ color: ColorScheme) -> some View {
        CalendarView(
            viewModel: CalendarViewModel(
                dateObservable: selected,
                hoverObservable: hovered,
                enabledCalendars: .empty(),
                calendarService: calendarService,
                dateProvider: dateProvider,
                settings: settings,
                notificationCenter: notificationCenter
            ),
            hoverObserver: hovered.asObserver(),
            clickObserver: selected.asObserver()
        )
        .preview()
        .fixedSize()
        .preferredColorScheme(color)
    }

    /// live preview doesn't work well with both color schemes enabled
    static var previews: some View {
        make(.dark)
        make(.light)
    }
}

private extension MockCalendarServiceProvider {

    init(dateProvider: DateProviding) {
        self.init(
            events: (0..<30).map { _ in
                let date: Date = .random(from: dateProvider)
                return .make(start: date, end: date, calendar: .make(color: .random()))
            },
            calendars: [],
            dateProvider: dateProvider
        )
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
