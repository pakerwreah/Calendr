//
//  CalendarExtensionTests.swift
//  CalendrTests
//
//  Created by Paker on 01/01/21.
//

import Foundation
import Testing
@testable import Calendr

class CalendarExtensionTests {

    @Test func testDateInRange() {
        let date: Date = .make(day: 5)

        let ranges: [(start: Date, end: Date, expected: Bool)] = [
            (.make(day: 2), .make(day: 1), false), // invalid range
            (.make(day: 1), .make(day: 5), false),
            (.make(day: 6), .make(day: 10), false),
            (.make(day: 1), .make(day: 5, second: 1), true), // including end
            (.make(day: 5), .make(day: 5), true),
            (.make(day: 5), .make(day: 6), true),
            (.make(day: 4), .make(day: 6), true)
        ]

        for (start, end, expected) in ranges {
            let result = Calendar.gregorian.isDay(date, inDays: (start, end))
            #expect(expected == result, "\(start) - \(end))")
        }
    }
}

private extension Date {
    static func make(day: Int, second: Int = 0) -> Date {
        make(year: 2021, month: 1, day: day, second: second)
    }
}
