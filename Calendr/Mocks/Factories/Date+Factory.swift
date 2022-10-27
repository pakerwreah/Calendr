//
//  Date+Factory.swift
//  Calendr
//
//  Created by Paker on 01/01/21.
//

#if DEBUG

import Foundation

extension Date {

    static func make(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        timeZone: TimeZone = .utc
    ) -> Date {

        Calendar.gregorian.with(timeZone: timeZone).date(
            from: .init(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        )!
    }

    enum At {
        case start
        case end
    }

    static func make(
        year: Int,
        month: Int,
        day: Int,
        at: At,
        timeZone: TimeZone = .utc
    ) -> Date {

        make(
            year: year,
            month: month,
            day: day,
            hour: at ~= .start ? 0 : 23,
            minute: at ~= .start ? 0 : 59,
            second: at ~= .start ? 0 : 59
        )
    }
}

#endif
