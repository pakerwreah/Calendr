//
//  EventModel.swift
//  CalendrTests
//
//  Created by Paker on 14/01/21.
//

import Foundation
@testable import Calendr

extension EventModel {
    static func make(
        start: Date = Date(),
        end: Date = Date(),
        title: String = "",
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        isAllDay: Bool = false,
        isPending: Bool = false,
        calendar: CalendarModel = .make()
    ) -> EventModel {

        .init(
            start: start,
            end: end,
            title: title,
            location: location,
            notes: notes,
            url: url,
            isAllDay: isAllDay,
            isPending: isPending,
            calendar: calendar
        )
    }
}
