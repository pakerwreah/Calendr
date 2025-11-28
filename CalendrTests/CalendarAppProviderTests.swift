//
//  CalendarAppProviderTests.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

import XCTest
import RxSwift
import Clocks
@testable import Calendr

class CalendarAppProviderTests: XCTestCase {

    let dateProvider = MockDateProvider()
    let appleScriptRunner = MockScriptRunner()

    func makeCalendarAppProvider(clock: ClockProviding) -> CalendarAppProviding {
        CalendarAppProvider(
            dateProvider: dateProvider,
            appleScriptRunner: appleScriptRunner,
            clock: clock
        )
    }
    lazy var calendarAppProvider = makeCalendarAppProvider(clock: .immediate)
    lazy var workspace = MockWorkspaceServiceProvider(dateProvider: dateProvider)

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")
        dateProvider.m_calendar.firstWeekday = 1
    }

    // MARK: - Apple Calendar

    func testOpenEvent_inCalendarApp() async {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        await calendarAppProvider.open(.make(id: "12345"), preferring: .calendar, using: workspace)

        await fulfillment(of: [openExpectation], timeout: 1)
    }

    func testOpenEvent_withRecurrenceRules_inCalendarApp() async {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+3")!

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T000000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        await calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                hasRecurrenceRules: true
            ),
            preferring: .calendar,
            using: workspace
        )

        await fulfillment(of: [openExpectation], timeout: 1)
    }

    func testOpenAllDayEvent_withRecurrenceRules_inCalendarApp_shouldUseTimeZone() async {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+3")!

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T030000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        await calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                isAllDay: true,
                hasRecurrenceRules: true
            ),
            preferring: .calendar,
            using: workspace
        )

        await fulfillment(of: [openExpectation], timeout: 1)
    }

    func testOpenReminder_inCalendarApp() async {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "x-apple-reminderkit://remcdreminder/12345")
            openExpectation.fulfill()
        }

        await calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                type: .reminder(completed: false)
            ),
            preferring: .calendar,
            using: workspace
        )

        await fulfillment(of: [openExpectation], timeout: 1)
    }

    // MARK: - Notion Calendar

    func testOpenEvent_inNotionApp() async {
        let openDateExpectation = expectation(description: "Open Date")
        let openEventExpectation = expectation(description: "Open Event")

        let clock = TestClock()
        let calendarAppProvider = makeCalendarAppProvider(clock: clock)

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString.components(separatedBy: "?t=").first, "cron://./2025/1/1")
            openDateExpectation.fulfill()
        }

        async let _ = calendarAppProvider.open(
            .make(
                id: "nope!",
                externalId: "12345",
                start: .make(year: 2025, month: 1, day: 1, hour: 12, minute: 10, second: 5),
                end: .make(year: 2025, month: 1, day: 1, hour: 15, minute: 25, second: 55),
                calendar: .make(email: "test@example.com")
            ),
            preferring: .notion,
            using: workspace
        )

        await fulfillment(of: [openDateExpectation], timeout: 1)

        workspace.didOpenURL = { url in
            XCTAssertEqual(
                url.absoluteString,
                "cron://showEvent?accountEmail=test%40example.com&iCalUID=12345" +
                "&startDate=2025-01-01T12:10:05.000Z&endDate=2025-01-01T15:25:55.000Z" +
                "&title=Title&ref=br.paker.Calendr"
            )
            openEventExpectation.fulfill()
        }

        await clock.advance(by: .seconds(1))

        await fulfillment(of: [openEventExpectation], timeout: 1)
    }

    func testOpenDay_inCalendarApp() async {
        let openExpectation = expectation(description: "Open")
        let dateExpectation = expectation(description: "Date")

        let clock = TestClock()
        let calendarAppProvider = makeCalendarAppProvider(clock: clock)

        appleScriptRunner.didRunScript = { source in
            XCTAssertEqual(source, """
                tell application "Calendar"
                switch view to day view
                end tell
            """)
            openExpectation.fulfill()
        }

        async let _ = calendarAppProvider.open(.calendar, at: .make(year: 2025, month: 1, day: 1), mode: .day, using: workspace)

        await fulfillment(of: [openExpectation], timeout: 1)

        appleScriptRunner.didRunScript = { source in
            XCTAssertEqual(source, """
                set theDate to current date
                set day of theDate to 1
                set month of theDate to 1
                set year of theDate to 2025
                tell application "Calendar"
                view calendar at theDate
                activate
                end tell
            """)
            dateExpectation.fulfill()
        }

        await clock.advance(by: .seconds(0.3))

        await fulfillment(of: [dateExpectation], timeout: 1)
    }

    func testOpenWeek_inCalendarApp() async {
        let openExpectation = expectation(description: "Open")
        let dateExpectation = expectation(description: "Date")

        let clock = TestClock()
        let calendarAppProvider = makeCalendarAppProvider(clock: clock)

        appleScriptRunner.didRunScript = { source in
            XCTAssertEqual(source, """
                tell application "Calendar"
                switch view to week view
                end tell
            """)
            openExpectation.fulfill()
        }

        async let _ = calendarAppProvider.open(.calendar, at: .make(year: 2025, month: 1, day: 1), mode: .week, using: workspace)

        await fulfillment(of: [openExpectation], timeout: 1)

        appleScriptRunner.didRunScript = { source in
            XCTAssertEqual(source, """
                set theDate to current date
                set day of theDate to 29
                set month of theDate to 12
                set year of theDate to 2024
                tell application "Calendar"
                view calendar at theDate
                activate
                end tell
            """)
            dateExpectation.fulfill()
        }

        await clock.advance(by: .seconds(0.3))

        await fulfillment(of: [dateExpectation], timeout: 1)
    }

    func testOpenDate_inNotionApp() async {
        let openExpectation = expectation(description: "Open")
        openExpectation.assertForOverFulfill = false

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString.components(separatedBy: "?t=").first, "cron://./2025/1/1")
            openExpectation.fulfill()
        }

        async let _ = calendarAppProvider.open(.notion, at: .make(year: 2025, month: 1, day: 1), mode: .day, using: workspace)

        await fulfillment(of: [openExpectation], timeout: 1)
    }

    func testOpenReminder_inNotionApp_shouldFallbackToCalendarApp() async  {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "x-apple-reminderkit://remcdreminder/12345")
            openExpectation.fulfill()
        }

        async let _ = calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                type: .reminder(completed: false)
            ),
            preferring: .notion,
            using: workspace
        )

        await fulfillment(of: [openExpectation], timeout: 1)
    }
}
