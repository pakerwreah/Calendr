//
//  DateIntervalFormatterTests.swift
//  CalendrTests
//
//  Created by Paker on 28/03/2021.
//

import XCTest
@testable import Calendr

class DateIntervalFormatterTests: XCTestCase {

    let oldFormatter = Foundation.DateIntervalFormatter()
    let newFormatter = Calendr.DateIntervalFormatter()
    let date: Date = .make(year: 2021, month: 1, day: 5)

    override func setUp() {
        oldFormatter.calendar = .reference
        newFormatter.calendar = .reference
    }

    /// ├week of month: 2┤
    func testDateWeekFormat() {

        oldFormatter.dateTemplate = "MW"
        newFormatter.dateTemplate = "MW"

        XCTAssertEqual(oldFormatter.string(from: date, to: date), "1 ├week of month: 2┤")
        XCTAssertEqual(newFormatter.string(from: date, to: date), "1 2")
    }

    /// (quarter: 1)
    func testDateQuarterFormat() {

        oldFormatter.dateTemplate = "MQ"
        newFormatter.dateTemplate = "MQ"

        XCTAssertEqual(oldFormatter.string(from: date, to: date), "1 (quarter: 1)")
        XCTAssertEqual(newFormatter.string(from: date, to: date), "1 1")
    }
}
