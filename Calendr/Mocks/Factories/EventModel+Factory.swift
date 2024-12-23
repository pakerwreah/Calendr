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
        title: String = "Title",
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        isAllDay: Bool = false,
        type: EventType = .event(.accepted),
        calendar: CalendarModel = .make(),
        participants: [Participant] = [],
        timeZone: TimeZone? = nil,
        hasRecurrenceRules: Bool = false,
        priority: Priority? = nil
    ) -> EventModel {

        .init(
            id: id,
            start: start,
            end: type.isReminder ? Calendar.gregorian.endOfDay(for: start) : end,
            title: title,
            location: location,
            coordinates: nil,
            notes: notes,
            url: url,
            isAllDay: isAllDay || type.isBirthday,
            type: type,
            calendar: calendar,
            participants: participants,
            timeZone: timeZone,
            hasRecurrenceRules: hasRecurrenceRules,
            priority: priority
        )
    }
}

extension Participant {

    static func make(
        name: String = "",
        status: EventStatus = .unknown,
        isOrganizer: Bool = false,
        isCurrentUser: Bool = false
    ) -> Participant {

        .init(
            name: name,
            status: status,
            isOrganizer: isOrganizer,
            isCurrentUser: isCurrentUser
        )
    }
}

#endif
