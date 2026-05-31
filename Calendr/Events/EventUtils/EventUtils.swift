//
//  EventUtils.swift
//  Calendr
//
//  Created by Paker on 28/02/23.
//

import Foundation

enum EventUtils {

    static func duration(
        from start: Date,
        to end: Date,
        timeZone: TimeZone?,
        formatter: DateIntervalFormatter
    ) -> String {

        guard
            let timeZone, timeZone != formatter.timeZone,
            let tz_abbreviation = timeZone.abbreviation(for: start)
        else {
            return formatter.string(from: start, to: end)
        }

        let origTimeZone = formatter.timeZone
        defer { formatter.timeZone = origTimeZone }
        formatter.timeZone = timeZone

        return "\(formatter.string(from: start, to: end)) (\(tz_abbreviation))"
    }

    static func duration(
        for event: EventModel,
        using dateProvider: DateProviding,
        dateStyle: DateIntervalFormatter.Style,
        timeStyle: DateIntervalFormatter.Style,
        forceLocalTimeZone: Bool
    ) -> String {

        let formatter = DateIntervalFormatter()
        formatter.dateStyle = dateStyle
        formatter.calendar = dateProvider.calendar

        if event.isAllDay {
            formatter.timeStyle = .none
            return formatter.string(from: event.start, to: event.end)
        } else {
            formatter.timeStyle = timeStyle

            let range = event.range(using: dateProvider)

            let end: Date

            if event.type.isReminder {
                end = event.start
            }
            else if range.isSingleDay && range.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            let timeZone = event.isMeeting || forceLocalTimeZone ? nil : event.timeZone

            return EventUtils.duration(
                from: event.start,
                to: end,
                timeZone: timeZone,
                formatter: formatter
            )
        }
    }
}
