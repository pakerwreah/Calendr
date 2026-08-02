//
//  CalendarPicker.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import AppKit
import SwiftUI

struct CalendarPicker: View {

    let calendarSections: [CalendarSection]
    @Binding var selectedCalendarId: String?
    let selectedCalendarColor: NSColor

    var body: some View {
        Menu {
            Picker("", selection: $selectedCalendarId) {
                ForEach(calendarSections, id: \.account) { section in
                    Section(section.account.title) {
                        ForEach(section.calendars, id: \.id) { calendar in
                            Button(calendar.title, systemImage: "circle.fill") {}
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color(nsColor: calendar.color))
                                .tag(calendar.id)
                        }
                    }
                }
            }
            .labelsHidden()
        } label: {
            Image(systemName: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(nsColor: selectedCalendarColor))
        }
        .pickerStyle(.inline)
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
