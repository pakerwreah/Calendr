//
//  EventViewPreview.swift
//  CalendrTests
//
//  Created by Paker on 06/03/2021.
//

#if DEBUG

import SwiftUI

private final class EventViewPreview: NSViewRepresentable {

    let now = Date()
    let dateProvider = DateProvider(calendar: .current)
    let calendarService = CalendarServiceProvider()
    let workspace = WorkspaceServiceProvider()
    lazy var settings = SettingsViewModel(
        dateProvider: dateProvider,
        userDefaults: .init(),
        notificationCenter: .init()
    )

    func makeNSView(context: Context) -> EventView {
        EventView(
            viewModel: EventViewModel(
                event: EventModel(
                    id: "",
                    start: now + 5,
                    end: now + 15,
                    title: "Test Event",
                    location: "Brasil",
                    notes: "Join at http://meet.google.com",
                    url: nil,
                    isAllDay: false,
                    isPending: false,
                    type: .event,
                    calendar: CalendarModel(
                        identifier: "",
                        account: "",
                        title: "",
                        color: .systemYellow
                    )
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings
            )
        )
    }

    func updateNSView(_ nsView: EventView, context: Context) {
    }
}

@available(OSX 11.0, *)
struct EventView_Previews: PreviewProvider {

    static func make(_ color: ColorScheme) -> some View {
        ZStack {
            Color(.controlBackgroundColor)
            EventViewPreview()
        }
        .frame(width: 180, height: 50)
        .preferredColorScheme(color)
    }

    static var previews: some View {
        make(.dark)
        make(.light)
    }
}

#endif
