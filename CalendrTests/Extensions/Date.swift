//
//  Date.swift
//  CalendrTests
//
//  Created by Paker on 01/01/21.
//

import Foundation

extension Date {

    static func make(
        year: Int = 2020,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {

        Calendar.current.date(
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
