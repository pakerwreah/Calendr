//
//  EventViewPreview.swift
//  CalendrTests
//
//  Created by Paker on 06/03/2021.
//

#if DEBUG

import SwiftUI
import RxSwift

struct EventViewPreview: PreviewProvider {

    static let dateProvider = MockDateProvider()
    static let calendarService = MockCalendarServiceProvider()
    static let workspace = NSWorkspace.shared
    static let popoverSettings = MockPopoverSettings()

    static func make(_ color: ColorScheme) -> some View {
        EventView(
            viewModel: EventViewModel(
                event: .make(
                    start: dateProvider.now + 5,
                    end: dateProvider.now + 15,
                    title: "Test Event",
                    location: "Brasil",
                    notes: "Join at http://meet.google.com",
                    type: .event(.declined),
                    calendar: .make(color: .systemYellow)
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                popoverSettings: popoverSettings,
                isShowingDetails: .dummy(),
                scheduler: MainScheduler.instance
            )
        )
        .preview()
        .frame(width: 180, height: 50)
        .preferredColorScheme(color)
        .padding(5)
    }

    /// live preview doesn't work well with both color schemes enabled
    static var previews: some View {
        make(.dark)
        make(.light)
    }
}

#endif
