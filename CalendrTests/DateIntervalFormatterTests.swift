//
//  DateIntervalFormatterTests.swift
//  CalendrTests
//
//  Created by Paker on 28/03/2021.
//

import XCTest
@testable import Calendr

class DateIntervalFormatterTests: XCTestCase {

    let formatter = Calendr.DateIntervalFormatter()
    let date: Date = .make(year: 2021, month: 1, day: 5)

    override func setUp() {
        formatter.calendar = .reference
    }

    /// ├week of month: 2┤
    func testDateWeekFormat() {

        formatter.dateTemplate = "MW"

        XCTAssertEqual(formatter.string(from: date, to: date), "1 2")
    }

    /// (quarter: 1)
    func testDateQuarterFormat() {

        formatter.dateTemplate = "MQ"

        XCTAssertEqual(formatter.string(from: date, to: date), "1 1")
    }
}
