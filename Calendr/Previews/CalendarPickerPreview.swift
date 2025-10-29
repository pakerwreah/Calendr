//
//  CalendarPickerPreview.swift
//  Calendr
//
//  Created by Paker on 11/11/24.
//

#if DEBUG

import SwiftUI

struct CalendarPickerPreview: PreviewProvider {

    static let localStorage = {
        let localStorage: LocalStorageProvider = .shared

        localStorage.showEventStatusItem = true
        localStorage.silencedCalendars = [CalendarModel].mock
            .enumerated()
            .filter { $0.offset % 3 == 0 }
            .map(\.element.id)

        return localStorage
    }()

    static let calendarService = MockCalendarServiceProvider(calendars: .mock)

    static var previews: some View {
        CalendarPickerViewController(
            viewModel: CalendarPickerViewModel(
                calendarService: calendarService,
                localStorage: localStorage
            ),
            configuration: .picker
        )
        .view.preview()
        .frame(minWidth: 250)
        .fixedSize()
    }
}

private extension Array where Element == CalendarModel {

    private static var uuid: String { UUID().uuidString  }

    static let mock: Self = [
        .make(id: uuid, account: "Google", title: "Gmail", color: .systemRed),
        .make(id: uuid, account: "iCloud", title: "Personal", color: .systemYellow),
        .make(id: uuid, account: "iCloud", title: "Reminders", color: .systemOrange),
        .make(id: uuid, account: Strings.Calendars.Source.others, title: "Birthdays", color: .systemGray),
        .make(id: uuid, account: "Work", title: "Meetings", color: .systemPink),
        .make(id: uuid, account: "Work", title: "Tasks", color: .systemTeal),
        .make(id: uuid, account: Strings.Calendars.Source.others, title: "Holidays", color: .systemGreen, isSubscribed: true),
    ]
}

#endif
