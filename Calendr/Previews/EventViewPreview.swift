//
//  EventViewPreview.swift
//  CalendrTests
//
//  Created by Paker on 06/03/2021.
//

#if DEBUG

import SwiftUI

private struct EventViewPreview: NSViewRepresentable {

    let now = Date()

    func makeNSView(context: Context) -> EventView {
        EventView(
            viewModel: EventViewModel(
                event: EventModel(
                    start: now + 5,
                    end: now + 15,
                    title: "Test Event",
                    location: "Brasil",
                    notes: "Join at zoom.us/j/0000000000",
                    url: URL(string: "https://google.com"),
                    isAllDay: false,
                    isPending: false,
                    isBirthday: true,
                    calendar: CalendarModel(
                        identifier: "",
                        account: "",
                        title: "",
                        color: NSColor.systemYellow.cgColor
                    )
                ),
                dateProvider: DateProvider(calendar: .current),
                workspaceProvider: WorkspaceProvider()
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
            Color(.windowBackgroundColor)
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
