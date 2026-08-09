//
//  EventTitleDateParserTests.swift
//  Calendr
//

import Foundation
import Testing
@testable import Calendr

class EventTitleDateParserTests {

    // A decimal time such as "9.30" is also a valid numeric date (Sep 30). Both
    // the time matcher ("at 9") and the numeric-date matcher ("9.30") fire and
    // their ranges overlap on the shared digit, which used to throw
    // NSRangeException while building the cleaned title. Pin a month-first
    // locale so "9.30" is always read as a valid date and that overlap path is
    // always exercised regardless of the host locale.
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    @Test func decimalTimeDoesNotCrash() {
        // Each input yields an overlapping time + numeric-date token pair — the
        // exact precondition of the original NSRangeException crash. Note: "9.30"
        // is parsed as a numeric DATE (Sep 30), not a time — decimal times are
        // not recognized by the time matcher today. That semantic limitation is
        // out of scope for this crash-regression test (see report).
        let cases: [(input: String, expectedTitle: String)] = [
            ("Meeting at 9.30", "Meeting"),
            ("Call at 3.15",    "Call"),
            ("Sync at 12.30",   "Sync"),
            ("X at 9.30",       "X"),
        ]

        for (input, expectedTitle) in cases {
            let result = EventTitleDateParser.parse(input, calendar: calendar)

            // The call itself completing is the crash-regression assertion.
            #expect(result.cleanedTitle == expectedTitle, "\(input)")

            // Guard against a false green: both a time and a date token must be
            // present, otherwise the overlap path is not being exercised.
            #expect(result.tokens.contains { $0.kind == .time }, "\(input)")
            #expect(result.tokens.contains { $0.kind == .date }, "\(input)")
        }
    }

    @Test func decimalTimeOverlapIsLocaleIndependent() {
        // The crash class is not specific to month-first locales: when both date
        // components are <= 12 (e.g. "9.9") the numeric-date matcher accepts the
        // value under any locale, so the time/date overlap fires regardless.
        var dayFirstCalendar = Calendar(identifier: .gregorian)
        dayFirstCalendar.locale = Locale(identifier: "en_GB")

        let cases: [(input: String, expectedTitle: String)] = [
            ("Meeting at 9.9",  "Meeting"),
            ("Call at 10.10",   "Call"),
        ]

        for (input, expectedTitle) in cases {
            let result = EventTitleDateParser.parse(input, calendar: dayFirstCalendar)
            #expect(result.cleanedTitle == expectedTitle, "\(input)")
            #expect(result.tokens.contains { $0.kind == .time }, "\(input)")
            #expect(result.tokens.contains { $0.kind == .date }, "\(input)")
        }
    }

    @Test func colonTimeStillStrippedFromTitle() {
        let result = EventTitleDateParser.parse("Meeting at 9:30", calendar: calendar)
        #expect(result.cleanedTitle == "Meeting")
        #expect(result.tokens.contains { $0.kind == .time })
    }
}
