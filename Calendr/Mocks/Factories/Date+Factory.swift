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

}

#endif
