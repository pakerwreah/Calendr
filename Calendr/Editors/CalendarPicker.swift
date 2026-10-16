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
            SwiftUI.Label {
                Text(selectedCalendarTitle)
            } icon: {
                Image(systemName: "circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color(nsColor: selectedCalendarColor))
                    .imageScale(.small)
            }
            .labelStyle(.titleAndIcon)
        }
        .pickerStyle(.inline)
        .menuStyle(.borderlessButton)
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: 180)
        .fixedSize()
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color(nsColor: selectedCalendarColor).opacity(0.15))
        )
    }

    private var selectedCalendarTitle: String {
        calendarSections
            .lazy
            .flatMap(\.calendars)
            .first { $0.id == selectedCalendarId }?
            .title ?? ""
    }
}
