//
//  NextEventPreview.swift
//  Calendr
//
//  Created by Paker on 07/04/24.
//

#if DEBUG

import SwiftUI
import RxSwift

struct NextEventPreview: PreviewProvider {

    static let dateProvider = MockDateProvider()
    static let calendarService = MockCalendarServiceProvider(events: events, dateProvider: dateProvider)
    static let geocoder = MockGeocodeServiceProvider()
    static let screenProvider = MockScreenProvider(screen: MockScreen(hasNotch: true))
    static let settings = MockNextEventSettings(showItem: true, fontSize: 13, length: 30, detectNotch: false)
    static let notificationCenter = NotificationCenter()
    static let workspace = NSWorkspace.shared

    static let events: [EventModel] = [
        .make(
            start: dateProvider.now + 5,
            end: dateProvider.now + 999,
            title: "Test with a very long event name and some more extra text",
            type: .event(.accepted),
            calendar: .make(color: .systemYellow)
        )
    ]

    static var previews: some View {
        NextEventView(
            viewModel: NextEventViewModel(
                type: .event,
                userDefaults: .init(),
                settings: settings,
                nextEventCalendars: .just([]),
                dateProvider: dateProvider,
                calendarService: calendarService,
                geocoder: geocoder,
                workspace: workspace,
                screenProvider: screenProvider,
                isShowingDetails: .dummy(),
                scheduler: MainScheduler.instance
            )
        )
        .preview()
        .fixedSize()
        .frame(maxWidth: 300)
        .padding(5)
    }
}

#endif
