//
//  DateComponentsTests.swift
//  Calendr
//
//  Created by Paker on 28/03/2026.
//

import XCTest
@testable import Calendr

final class DateComponentsTests: XCTestCase {

    let dateProvider = MockDateProvider()

    func testDateComponents_fromGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .gregorian).with(timeZone: timeZone)

        let components = date.dateComponents(using: dateProvider)

        XCTAssertEqual(components.calendar?.identifier, .gregorian)
        XCTAssertEqual(components.hour, 3)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.year, 2024)
    }

    func testDateComponents_fromNonGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .islamicUmmAlQura).with(timeZone: timeZone)

        let components = date.dateComponents(using: dateProvider)

        XCTAssertEqual(components.calendar?.identifier, .islamicUmmAlQura)
        XCTAssertEqual(components.hour, 3)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.day, 29)
        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.year, 1445)
    }

    func testDateComponents_fromNonGregorianCalendar_toGregorianCalendar() {
        let date = ISO8601DateFormatter().date(from: "2024-03-10T00:30:00Z")!
        let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!

        dateProvider.m_calendar = Calendar(identifier: .islamicUmmAlQura).with(timeZone: timeZone)

        let components = date.dateComponents(using: dateProvider, calendar: .gregorian)

        XCTAssertEqual(components.calendar?.identifier, .gregorian)
        XCTAssertEqual(components.hour, 3)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.year, 2024)
    }
}
