//
//  CalendarAppProviderTests.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

import XCTest
import RxSwift
@testable import Calendr

class CalendarAppProviderTests: XCTestCase {

    let dateProvider = MockDateProvider()
    let appleScriptRunner = MockScriptRunner()

    lazy var calendarAppProvider = CalendarAppProvider(dateProvider: dateProvider, appleScriptRunner: appleScriptRunner)
    lazy var workspace = MockWorkspaceServiceProvider(dateProvider: dateProvider)

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")
        dateProvider.m_calendar.firstWeekday = 1
    }

    // MARK: - Apple Calendar

    func testOpenEvent_inCalendarApp() {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(.make(id: "12345"), preferring: .calendar, using: workspace)

        waitForExpectations(timeout: 1)
    }

    func testOpenEvent_withRecurrenceRules_inCalendarApp() {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+3")!

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T000000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                hasRecurrenceRules: true
            ),
            preferring: .calendar,
            using: workspace
        )

        waitForExpectations(timeout: 1)
    }

    func testOpenAllDayEvent_withRecurrenceRules_inCalendarApp_shouldUseTimeZone() {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+3")!

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T030000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                isAllDay: true,
                hasRecurrenceRules: true
            ),
            preferring: .calendar,
            using: workspace
        )

        waitForExpectations(timeout: 1)
    }

    func testOpenReminder_inCalendarApp() {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "x-apple-reminderkit://remcdreminder/12345")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                type: .reminder(completed: false)
            ),
            preferring: .calendar,
            using: workspace
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Notion Calendar

    func testOpenEvent_inNotionApp() {
        let openDateExpectation = expectation(description: "Open Date")
        let openEventExpectation = expectation(description: "Open Event")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString.components(separatedBy: "?t=").first, "cron://./2025/1/1")
            openDateExpectation.fulfill()
        }

        calendarAppProvider.open(
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

        wait(for: [openDateExpectation])

        workspace.didOpenURL = { url in
            XCTAssertEqual(
                url.absoluteString,
                "cron://showEvent?accountEmail=test%40example.com&iCalUID=12345" +
                "&startDate=2025-01-01T12:10:05.000Z&endDate=2025-01-01T15:25:55.000Z" +
                "&title=Title&ref=br.paker.Calendr"
            )
            openEventExpectation.fulfill()
        }

        wait(for: [openEventExpectation])
    }

    func testOpenDay_inCalendarApp() {
        let openExpectation = expectation(description: "Open")

        appleScriptRunner.didRunScript = { source in
            XCTAssert(source.contains("tell application \"Calendar\""))
            XCTAssert(source.contains("set day of theDate to 1"), source)
            XCTAssert(source.contains("set month of theDate to 1"), source)
            XCTAssert(source.contains("set year of theDate to 2025"), source)
            XCTAssert(source.contains("day view"))
            openExpectation.fulfill()
        }

        calendarAppProvider.open(.calendar, at: .make(year: 2025, month: 1, day: 1), mode: .day, using: workspace)

        waitForExpectations(timeout: 1)
    }

    func testOpenWeek_inCalendarApp() {
        let openExpectation = expectation(description: "Open")

        appleScriptRunner.didRunScript = { source in
            // opens at the start of the week
            XCTAssert(source.contains("tell application \"Calendar\""))
            XCTAssert(source.contains("set day of theDate to 29"), source)
            XCTAssert(source.contains("set month of theDate to 12"), source)
            XCTAssert(source.contains("set year of theDate to 2024"), source)
            XCTAssert(source.contains("week view"))
            openExpectation.fulfill()
        }

        calendarAppProvider.open(.calendar, at: .make(year: 2025, month: 1, day: 1), mode: .week, using: workspace)

        waitForExpectations(timeout: 1)
    }

    func testOpenDate_inNotionApp() {
        let openExpectation = expectation(description: "Open")
        openExpectation.assertForOverFulfill = false

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString.components(separatedBy: "?t=").first, "cron://./2025/1/1")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(.notion, at: .make(year: 2025, month: 1, day: 1), mode: .day, using: workspace)

        waitForExpectations(timeout: 1)
    }

    func testOpenReminder_inNotionApp_shouldFallbackToCalendarApp() {
        let openExpectation = expectation(description: "Open")

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "x-apple-reminderkit://remcdreminder/12345")
            openExpectation.fulfill()
        }

        calendarAppProvider.open(
            .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                type: .reminder(completed: false)
            ),
            preferring: .notion,
            using: workspace
        )

        waitForExpectations(timeout: 1)
    }
}
