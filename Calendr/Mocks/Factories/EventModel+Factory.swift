//
//  EventModel+Factory.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

#if DEBUG

import Foundation

extension EventModel {

    static func make(
        id: String = "",
        start: Date = Date(),
        end: Date = Date(),
        title: String = "",
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        isAllDay: Bool = false,
        isPending: Bool = false,
        type: EventType = .event,
        calendar: CalendarModel = .make()
    ) -> EventModel {

        .init(
            id: id,
            start: start,
            end: type.isReminder ? Calendar.gregorian.endOfDay(for: start) : end,
            title: title,
            location: location,
            notes: notes,
            url: url,
            isAllDay: isAllDay || type.isBirthday,
            isPending: isPending,
            type: type,
            calendar: calendar
        )
    }
}

#endif
