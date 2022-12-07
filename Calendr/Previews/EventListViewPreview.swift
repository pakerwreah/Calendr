//
//  EventListViewPreview.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import SwiftUI
import RxSwift

struct EventListViewPreview: PreviewProvider {

    static let dateProvider = MockDateProvider(start: .make(hour: 16, minute: 45))
    static let calendarService = MockCalendarServiceProvider()
    static let workspace = NSWorkspace.shared
    static let settings = MockEventListSettings()

    static var now: Date { dateProvider.now }

    static var previews: some View {
        EventListView(
            viewModel: EventListViewModel(
                eventsObservable: .just((now, [
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
                        title: "Some meeting 👔",
                        location: "zoom.us/j/9999999999",
                        calendar: .make(color: .systemGreen)
                    ),
                    .make(
                        start: .make(hour: 19, minute: 00),
                        title: "Take the trash out",
                        type: .reminder,
                        calendar: .make(color: .systemOrange)
                    ),
                ])),
                isShowingDetails: .init(value: false),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings,
                scheduler: MainScheduler.instance
            )
        )
        .preview()
        .frame(width: 210)
        .fixedSize()
        .padding(5)
    }
}

private extension Date {

    static func make(hour: Int, minute: Int) -> Date {
        .make(year: 2021, month: 1, day: 1, hour: hour, minute: minute)
    }
}

#endif
