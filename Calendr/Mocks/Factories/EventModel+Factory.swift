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
        id: String? = nil,
        externalId: String? = nil,
        start: Date = Date(),
        end: Date? = nil,
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
        priority: Priority? = nil,
        flagged: Bool = false,
        tags: [String] = []
    ) -> EventModel {

        let id = id ?? UUID().uuidString

        let externalId = externalId ?? UUID().uuidString

        let end = type.isReminder
        ? Calendar.gregorian.endOfDay(for: start)
        : end ?? start.addingTimeInterval(3600)

        return .init(
            id: id,
            externalId: externalId,
            start: start,
            end: end,
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
            priority: priority,
            attachments: [],
            flagged: flagged,
            tags: tags
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
