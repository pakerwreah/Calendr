//
//  EventListViewPreview.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import SwiftUI

struct EventListViewPreview: PreviewProvider {

    static let dateProvider = MockDateProvider(start: .make(hour: 16, minute: 45))
    static let calendarService = MockCalendarServiceProvider()
    static let workspace = WorkspaceServiceProvider()
    static let settings = MockEventListSettings()

    static var now: Date { dateProvider.now }

    static func make(_ color: ColorScheme) -> some View {
        EventListView(
            viewModel: EventListViewModel(
                dateObservable: .just(now),
                eventsObservable: .just([
                    .make(
                        start: .make(hour: 15, minute: 30),
                        end: .make(hour: 15, minute: 50),
                        title: "Drink some tea 🫖",
                        calendar: .make(color: .systemYellow)
                    ),
                    .make(
                        start: .make(hour: 16, minute: 00),
                        end: .make(hour: 17, minute: 00),
                        title: "Update Calendr screenshot 📷",
                        calendar: .make(color: .systemTeal)
                    ),
                    .make(
                        start: .make(hour: 17, minute: 00),
                        end: .make(hour: 18, minute: 00),
                        title: "some meeting 👔",
                        location: "zoom.us/j/9999999999",
                        calendar: .make(color: .systemGreen)
                    ),
                    .make(
                        start: .make(hour: 19, minute: 00),
                        title: "Take the trash out",
                        type: .reminder,
                        calendar: .make(color: .systemOrange)
                    ),
                ]),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings
            )
        )
        .preview()
        .frame(width: 210)
        .fixedSize()
        .padding(5)
        .preferredColorScheme(color)
    }

    /// live preview doesn't work well with both color schemes enabled
    static var previews: some View {
        make(.dark)
        make(.light)
    }
}

private extension Date {

    static func make(hour: Int, minute: Int) -> Date {
        .make(year: 2021, month: 1, day: 1, hour: hour, minute: minute)
    }
}

#endif
