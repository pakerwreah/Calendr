//
//  DateExtensionsTests.swift
//  Calendr
//
//  Created by Paker on 11/08/2026.
//

import Foundation
import Testing
@testable import Calendr

final class DateExtensionsTests {

    let dateProvider = MockDateProvider()

    @Test func testDateComponents_fromGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .gregorian).with(timeZone: timeZone)

        let components = date.components(using: dateProvider)

        #expect(components.calendar?.identifier == .gregorian)
        #expect(components.hour == 3)
        #expect(components.minute == 30)
        #expect(components.day == 10)
        #expect(components.month == 3)
        #expect(components.year == 2024)
    }

    @Test func testDateComponents_fromNonGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .islamicUmmAlQura).with(timeZone: timeZone)

        let components = date.components(using: dateProvider)

        #expect(components.calendar?.identifier == .islamicUmmAlQura)
        #expect(components.hour == 3)
        #expect(components.minute == 30)
        #expect(components.day == 29)
        #expect(components.month == 8)
        #expect(components.year == 1445)
    }

    @Test func testDateComponents_fromNonGregorianCalendar_toGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .islamicUmmAlQura).with(timeZone: timeZone)

        let components = date.components(using: dateProvider, calendar: .gregorian)

        #expect(components.calendar?.identifier == .gregorian)
        #expect(components.hour == 3)
        #expect(components.minute == 30)
        #expect(components.day == 10)
        #expect(components.month == 3)
        #expect(components.year == 2024)
    }

    @Test func testTruncating() {

        let dateProvider = MockDateProvider()

        let date: Date = .make(year: 2025, month: 10, day: 5, hour: 10, minute: 30, second: 50)

        let minute: Date = date.start(of: .minute, using: dateProvider)
        #expect(minute == .make(year: 2025, month: 10, day: 5, hour: 10, minute: 30))

        let hour: Date = date.start(of: .hour, using: dateProvider)
        #expect(hour == .make(year: 2025, month: 10, day: 5, hour: 10))

        let day: Date = date.start(of: .day, using: dateProvider)
        #expect(day == .make(year: 2025, month: 10, day: 5))

        let month: Date = date.start(of: .month, using: dateProvider)
        #expect(month == .make(year: 2025, month: 10, day: 1))

        let year: Date = date.start(of: .year, using: dateProvider)
        #expect(year == .make(year: 2025, month: 1, day: 1))
    }

    @Test func testAddingDateComponents() {

        let dateProvider = MockDateProvider()

        let result: Date = .make(year: 2025, month: 10, day: 5, at: .start)
            .adding(.init(hour: 15, minute: 40), using: dateProvider)

        #expect(result == .make(year: 2025, month: 10, day: 5, hour: 15, minute: 40, second: 0))
    }
}
