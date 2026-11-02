//
//  EventDurationTests.swift
//  CalendrTests
//
//  Created by Paker on 02/11/2026.
//

import Foundation
import Testing
@testable import Calendr

class EventDurationTests {

    @Test func testDuration_withDifferentTimeZone_shouldUseTimeZoneAndRestoreFormatter() {

        let formatter = makeFormatter()
        let timeZone = TimeZone(abbreviation: "GMT-3")!

        let duration = EventDuration.duration(
            from: .make(year: 2021, month: 1, day: 1, hour: 15),
            to: .make(year: 2021, month: 1, day: 1, hour: 16),
            timeZone: timeZone,
            formatter: formatter
        )

        #expect(duration == "12:00 - 1:00 PM (GMT-3)")
        #expect(formatter.timeZone == .utc)
    }

    @Test func testDuration_withFormatterTimeZone_shouldNotAppendTimeZone() {

        let formatter = makeFormatter()

        let duration = EventDuration.duration(
            from: .make(year: 2021, month: 1, day: 1, hour: 15),
            to: .make(year: 2021, month: 1, day: 1, hour: 16),
            timeZone: .utc,
            formatter: formatter
        )

        #expect(duration == "3:00 - 4:00 PM")
    }

    @Test func testDuration_forSingleDayAllDayEvent_withoutPreferredDateStyle_shouldUseLongDateStyle() {

        let dateProvider = MockDateProvider()
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let duration = EventDuration.duration(
            for: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            ),
            using: dateProvider,
            preferredDateStyle: .none,
            preferredTimeStyle: .short,
            forceLocalTimeZone: false
        )

        #expect(duration == "January 1, 2021")
    }

    @Test func testDuration_forMultiDayAllDayEvent_withoutPreferredDateStyle_shouldUseLongDateStyle() {

        let dateProvider = MockDateProvider()
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let duration = EventDuration.duration(
            for: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2),
                isAllDay: true
            ),
            using: dateProvider,
            preferredDateStyle: .none,
            preferredTimeStyle: .short,
            forceLocalTimeZone: false
        )

        #expect(duration == "January 1 - 2, 2021")
    }

    @Test func testDuration_forFloatingEvent_shouldUseSystemTimeZone() {

        let systemTimeZone = TimeZone(abbreviation: "GMT-3")!
        let dateProvider = MockDateProvider(systemTimeZone: systemTimeZone)
        dateProvider.m_calendar = .gregorian.with(timeZone: .utc)
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let duration = EventDuration.duration(
            for: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15, timeZone: systemTimeZone),
                end: .make(year: 2021, month: 1, day: 1, hour: 16, timeZone: systemTimeZone)
            ),
            using: dateProvider,
            preferredDateStyle: .none,
            preferredTimeStyle: .short,
            forceLocalTimeZone: false
        )

        #expect(duration == "3:00 - 4:00 PM (GMT-3)")
    }

    @Test func testDuration_forFloatingEvent_crossingMidnight_shouldUseSystemTimeZoneForRange() {

        let systemTimeZone = TimeZone(abbreviation: "GMT-3")!
        let dateProvider = MockDateProvider(systemTimeZone: systemTimeZone)
        dateProvider.m_calendar = .gregorian.with(timeZone: .utc)
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let duration = EventDuration.duration(
            for: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 22, timeZone: systemTimeZone),
                end: .make(year: 2021, month: 1, day: 2, hour: 1, timeZone: systemTimeZone)
            ),
            using: dateProvider,
            preferredDateStyle: .none,
            preferredTimeStyle: .short,
            forceLocalTimeZone: false
        )

        #expect(duration == "Jan 1, 2021 at 10:00 PM - Jan 2, 2021 at 1:00 AM (GMT-3)")
    }
}

private func makeFormatter() -> Calendr.DateIntervalFormatter {

    let formatter = Calendr.DateIntervalFormatter()
    formatter.calendar = .gregorian.with(timeZone: .utc)
    formatter.locale = Locale(identifier: "en_US")
    formatter.timeZone = .utc
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}
