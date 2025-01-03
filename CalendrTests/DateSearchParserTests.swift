//
//  DateSearchParserTests.swift
//  Calendr
//
//  Created by Paker on 18/12/2021.
//

import XCTest
@testable import Calendr

class DateSearchParserTests: XCTestCase {

    let dateProvider = MockDateProvider()

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")
        dateProvider.now = .make(year: 2021, month: 12, day: 18)
    }

    func testValidDates() throws {
        // unfortunately, there's no way to mock the current date in NSDataDetector
        // and if it detects a date that's missing the year, it defaults to the closest year to that date
        let year = try XCTUnwrap(closestYearFor(day: 20, month: 12))

        var dateStrings: [(String, String)] = [
            ("2021-12-18",          "18/12/2021"),
            ("December 18, 2021",   "18/12/2021"),
            ("18 December 2021",    "18/12/2021"),
            ("18 Dec 2021",         "18/12/2021"),
            ("Dec 2021",            "18/12/2021"),
            ("Dec",                 "18/12/2021"),
            ("20Dec2021",           "20/12/2021"),
            ("20Dec",               "20/12/\(year)"),
            ("20 Dec",              "20/12/\(year)"),
            ("19 Decs 20 Dec",      "20/12/\(year)"),
        ]

        dateStrings += dateStrings.map { text, expected in (text.lowercased(), expected) }
        dateStrings += dateStrings.map { text, expected in ("Prefix \(text)", expected) }
        dateStrings += dateStrings.map { text, expected in ("\(text) Suffix", expected) }

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        for (text, expected) in dateStrings {
            let (date, _) = try XCTUnwrap(DateSearchParser.parse(text: text, using: dateProvider), text)
            XCTAssertEqual(formatter.string(from: date), expected, text)
        }
    }

    func testResult() throws {
        let text = "Search term 6 december 2022"
        let (date, result) = try XCTUnwrap(DateSearchParser.parse(text: text, using: dateProvider), text)

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        XCTAssertEqual(formatter.string(from: date), "06/12/2022")
        XCTAssertEqual(result, "Search term")
    }

    func testInvalidDates() throws {

        let dateStrings: [String] = [
            "2021-12-118",
            "Decembers 18, 2021",
            "18 Decembers 2021",
            "18 Decs 2021",
            "Decs 2021",
            "aDec 2021",
            "Decs",
            "aDec",
            "20 Decs",
            "20 aDec",
            "a20Dec",
        ]

        for text in dateStrings {
            XCTAssertNil(DateSearchParser.parse(text: text, using: dateProvider), text)
        }
    }
}

private func closestYearFor(day: Int, month: Int) -> Int? {
    let calendar = Calendar.current
    let today = Date()
    let currentYear = calendar.component(.year, from: today)

    return (-1...1)
        .compactMap { offset in
            calendar.date(from: DateComponents(year: currentYear + offset, month: month, day: day))
        }
        .min(by: { abs($0.timeIntervalSince(today)) < abs($1.timeIntervalSince(today)) })
        .map { calendar.component(.year, from: $0) }
}
