//
//  DateComponentsTests.swift
//  Calendr
//
//  Created by Paker on 28/03/2026.
//

import Foundation
import Testing
@testable import Calendr

final class DateComponentsTests {

    let dateProvider = MockDateProvider()

    @Test func testDateComponents_fromGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .gregorian).with(timeZone: timeZone)

        let components = date.dateComponents(using: dateProvider)

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

        let components = date.dateComponents(using: dateProvider)

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

        let components = date.dateComponents(using: dateProvider, calendar: .gregorian)

        #expect(components.calendar?.identifier == .gregorian)
        #expect(components.hour == 3)
        #expect(components.minute == 30)
        #expect(components.day == 10)
        #expect(components.month == 3)
        #expect(components.year == 2024)
    }
}
