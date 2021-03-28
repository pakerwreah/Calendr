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
    let locale = Locale(identifier: "en_US")
    let date: Date = .make(year: 2021, month: 1, day: 5)

    override func setUp() {
        oldFormatter.calendar = .reference
        oldFormatter.locale = locale
        newFormatter.calendar = .reference
        newFormatter.locale = locale
    }

    func testDateWeekFormat() {

        oldFormatter.dateTemplate = "YMW"
        newFormatter.dateTemplate = "YMW"

        XCTAssertEqual(oldFormatter.string(from: date, to: date), "1/2021 ├week of month: 2┤")
        XCTAssertEqual(newFormatter.string(from: date, to: date), "1/2021 2")
    }

    func testDateQuarterFormat() {

        oldFormatter.dateTemplate = "YMQ"
        newFormatter.dateTemplate = "YMQ"

        XCTAssertEqual(oldFormatter.string(from: date, to: date), "1/2021 (quarter: 1)")
        XCTAssertEqual(newFormatter.string(from: date, to: date), "1/2021 1")
    }
}
