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
        formatter: DateIntervalFormatter,
        isMeeting: Bool
    ) -> String {

        guard
            !isMeeting,
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
}
