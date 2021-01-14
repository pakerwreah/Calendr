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
        isAllDay: Bool,
        title: String,
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        calendar: CalendarModel
    ) -> EventModel {

        .init(
            start: start,
            end: end,
            isAllDay: isAllDay,
            title: title,
            location: location,
            notes: notes,
            url: url,
            calendar: calendar
        )
    }
}
