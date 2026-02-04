//
//  DateFormatRendererTests.swift
//  Calendr
//
//  Created by Paker on 04/02/26.
//

import XCTest
@testable import Calendr

final class DateFormatRendererTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private var date: Date!

    override func setUp() {
        super.setUp()
        // Create a fixed date for testing: 2026-02-04 15:30:45 UTC
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 4
        components.hour = 15
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(secondsFromGMT: 0)
        date = calendar.date(from: components)!
    }

    func testSimpleFormatWithoutTimezone() {
        let format = "HH:mm"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        XCTAssertEqual(result, "15:30")
    }

    func testTimezoneTokenReplacement() {
        let format = "HH:mm@GMT+2"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        // 15:30 UTC + 2 hours = 17:30
        XCTAssertEqual(result, "17:30")
    }

    func testMultipleTimezoneTokens() {
        let format = "HH:mm@GMT+0 HH:mm@GMT+5"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        // 15:30 UTC and 20:30 (15:30 + 5 hours)
        XCTAssertEqual(result, "15:30 20:30")
    }

    func testTimezoneTokenInsideQuotedLiteral() {
        // The timezone-like pattern inside quotes should NOT be processed
        let format = "'at@GMT+2' HH:mm"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        XCTAssertEqual(result, "at@GMT+2 15:30")
    }

    func testTimezoneTokenAfterQuotedLiteral() {
        let format = "'Time:' HH:mm@GMT+3"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        // 15:30 UTC + 3 hours = 18:30
        XCTAssertEqual(result, "Time: 18:30")
    }

    func testEscapedQuotesWithTimezonePattern() {
        // Format with escaped quotes ('') containing timezone-like pattern
        let format = "'It''s@GMT+1' HH:mm"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        XCTAssertEqual(result, "It's@GMT+1 15:30")
    }

    func testMixedQuotedAndUnquotedTimezoneTokens() {
        // Should only process the unquoted timezone token
        let format = "'Literal@GMT+1' HH:mm@GMT+2"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        // Only the second timezone token should be processed
        XCTAssertEqual(result, "Literal@GMT+1 17:30")
    }

    func testComplexFormatWithMultipleQuotes() {
        let format = "'Start' HH:mm@GMT+0 'at@GMT+5' 'End' HH:mm@GMT+3"
        let result = DateFormatRenderer.render(format: format, date: date, calendar: calendar)
        // First timezone: 15:30, second (in quotes): at@GMT+5, third timezone: 18:30
        XCTAssertEqual(result, "Start 15:30 at@GMT+5 End 18:30")
    }
}
