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
        start: Date,
        end: Date,
        isAllDay: Bool = false,
        title: String = "",
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        isPending: Bool = false,
        calendar: CalendarModel = .init(identifier: "", account: "", title: "", color: .clear)
    ) -> EventModel {

        .init(
            start: start,
            end: end,
            isAllDay: isAllDay,
            title: title,
            location: location,
            notes: notes,
            url: url,
            isPending: isPending,
            calendar: calendar
        )
    }
}
