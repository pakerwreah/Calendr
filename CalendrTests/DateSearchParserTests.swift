//
//  DateSearchParserTests.swift
//  Calendr
//
//  Created by Paker on 18/12/2021.
//

import Foundation
import Testing
@testable import Calendr

class DateSearchParserTests {

    let dateProvider = MockDateProvider()

    init() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")
        dateProvider.now = .make(year: 2021, month: 12, day: 18)
    }

    @Test func testValidDates() throws {
        // unfortunately, there's no way to mock the current date in NSDataDetector
        // and if it detects a date that's missing the year, it defaults to some year around that date 🔮
        func datesForMissingYear(_ date: String) -> [String] {
            let year = Calendar.current.component(.year, from: Date())
            return ["\(date)/\(year-1)", "\(date)/\(year)", "\(date)/\(year+1)"]
        }

        let datesFor20Dec = datesForMissingYear("20/12")

        var dateStrings: [(String, [String])] = [
            ("2021-12-18",          ["18/12/2021"]),
            ("December 18, 2021",   ["18/12/2021"]),
            ("18 December 2021",    ["18/12/2021"]),
            ("18 Dec 2021",         ["18/12/2021"]),
            ("Dec 2021",            ["18/12/2021"]),
            ("Dec",                 ["18/12/2021"]),
            ("20Dec2021",           ["20/12/2021"]),
            ("20Dec",               datesFor20Dec),
            ("20 Dec",              datesFor20Dec),
            ("19 Decs 20 Dec",      datesFor20Dec),
        ]

        dateStrings += dateStrings.map { text, expected in (text.lowercased(), expected) }
        dateStrings += dateStrings.map { text, expected in ("Prefix \(text)", expected) }
        dateStrings += dateStrings.map { text, expected in ("\(text) Suffix", expected) }

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        for (text, expected) in dateStrings {
            let (date, _) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")
            #expect(expected.contains(formatter.string(from: date)), "\(text)")
        }
    }

    @Test func testResult() throws {
        let text = "Search term 6 december 2022"
        let (date, result) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        #expect(formatter.string(from: date) == "06/12/2022")
        #expect(result == "Search term")
    }

    @Test func testResultWithDiacriticSearchTerm() throws {
        let text = "Café 6 december 2022"
        let (date, result) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        #expect(formatter.string(from: date) == "06/12/2022")
        #expect(result == "Café")
    }

    @Test func testResultWithMultiByteSearchTerm() throws {
        let text = "𠮷 6 december 2022"
        let (date, result) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        #expect(formatter.string(from: date) == "06/12/2022")
        #expect(result == "𠮷")
    }

    @Test func testYearIsNotExtractedFromTrailingNumber() throws {
        // An unrelated 4-digit number after the month (room/issue id, etc.) must
        // not be parsed as the year. With no year present, it falls back to the
        // current year (2021, from the fixed `dateProvider.now`).
        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        for text in ["Dec room 1234", "Dec #1234", "Dec sync 1234"] {
            let (date, _) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")
            #expect(formatter.string(from: date) == "18/12/2021", "\(text)")
        }
    }

    @Test func testYearIsNotExtractedFromLongerNumberRun() throws {
        // A 4-digit year must not be matched inside a longer digit run. No valid
        // year is found, so only the month token is consumed and the run stays in
        // the remaining search text.
        let (date, result) = try #require(DateSearchParser.parse(text: "Dec 20215", using: dateProvider))

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        #expect(formatter.string(from: date) == "18/12/2021")
        #expect(result == "20215")
    }

    @Test func testAdjacentYearIsStillExtracted() throws {
        // A standalone 4-digit year directly after the month keeps working, even
        // when trailing text follows it.
        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .short

        for text in ["Dec 2021", "Dec 2021 Suffix", "Prefix Dec 2021"] {
            let (date, _) = try #require(DateSearchParser.parse(text: text, using: dateProvider), "\(text)")
            #expect(formatter.string(from: date) == "18/12/2021", "\(text)")
        }
    }

    @Test func testInvalidDates() throws {        let dateStrings: [String] = [
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
            #expect(DateSearchParser.parse(text: text, using: dateProvider) == nil, "\(text)")
        }
    }
}
