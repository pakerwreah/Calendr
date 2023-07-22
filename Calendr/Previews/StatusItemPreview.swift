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
    static let settings = MockStatusItemSettings(showIcon: true, showDate: true, showIconDate: true, detectNotch: true)
    static let notificationCenter = NotificationCenter()

    static let events: [EventModel] = [
        .make(start: dateProvider.now, title: "John's Birthday", type: .birthday)
    ]

    static var previews: some View {
        let viewModel =  StatusItemViewModel(
            dateChanged: .just(()),
            nextEventCalendars: .just([]),
            settings: settings,
            dateProvider: dateProvider,
            screenProvider: screenProvider,
            calendarService: calendarService,
            notificationCenter: notificationCenter
        )

        var image: NSImage!
        _ = viewModel.image.bind { image = $0 }

        let button = NSButton(image: image, target: nil, action: nil)
        button.contentTintColor = .white
        button.isBordered = false

        return button
            .preview()
            .fixedSize()
            .padding(5)
    }
}

#endif
