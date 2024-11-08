//
//  StatusItemPreview.swift
//  Calendr
//
//  Created by Paker on 22/07/23.
//

#if DEBUG

import SwiftUI
import RxSwift

struct StatusItemPreview: PreviewProvider {

    static let dateProvider = MockDateProvider()
    static let calendarService = MockCalendarServiceProvider(events: events, dateProvider: dateProvider)
    static let screenProvider = MockScreenProvider(screen: MockScreen(hasNotch: true))
    static let settings = MockStatusItemSettings(
        showIcon: true, showDate: true, showBackground: true, iconStyle: .dayOfWeek, showNextEvent: true, textScaling: 1.6
    )
    static let notificationCenter = NotificationCenter()

    static let events: [EventModel] = [
        .make(start: dateProvider.now, title: "John's Birthday", type: .birthday)
    ]

    static var previews: some View {
        let viewModel = StatusItemViewModel(
            dateChanged: .void(),
            nextEventCalendars: .just([]),
            settings: settings,
            dateProvider: dateProvider,
            screenProvider: screenProvider,
            calendarService: calendarService,
            notificationCenter: notificationCenter,
            scheduler: MainScheduler.instance
        )

        let button = NSButton()
        button.contentTintColor = .white
        button.isBordered = false

        _ = viewModel.image.bind(to: button.rx.image)

        return button
            .preview()
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 150)
            .padding(5)
    }
}

#endif
