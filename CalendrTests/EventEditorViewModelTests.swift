//
//  EventEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class EventEditorViewModelTests: XCTestCase {

    private var dateProvider: MockDateProvider!

    override func setUp() {
        super.setUp()
        dateProvider = MockDateProvider()
        dateProvider.now = Date.make(year: 2025, month: 10, day: 25, hour: 10, minute: 30)
    }

    func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let start = dateProvider.now

        let viewModel = EventEditorViewModel(
            startDate: .init(date: start),
            dateProvider: dateProvider,
            calendarService: calendarService
        )

        let expectedEnd = dateProvider.calendar.date(byAdding: .hour, value: 1, to: start)!

        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.startDate, start)
        XCTAssertEqual(viewModel.endDate, expectedEnd)
        XCTAssertFalse(viewModel.isAllDay)
        XCTAssertEqual(viewModel.location, "")
        XCTAssertEqual(viewModel.url, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertFalse(viewModel.hasValidInput)
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
        XCTAssertTrue(viewModel.calendarSections.isEmpty)
        XCTAssertNil(viewModel.selectedCalendarId)
        XCTAssertEqual(viewModel.selectedCalendarColor, .clear)
    }

    func testViewModel_validTitle() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        XCTAssertFalse(viewModel.hasValidInput)

        viewModel.title = "   "
        XCTAssertFalse(viewModel.hasValidInput)

        viewModel.title = "Meeting"
        XCTAssertTrue(viewModel.hasValidInput)
    }

    func testViewModel_dateRange_timed_endEqualStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate

        XCTAssertFalse(viewModel.hasValidDateRange)
        XCTAssertFalse(viewModel.hasValidInput)
    }

    func testViewModel_dateRange_timed_endAfterStart_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.endDate = dateProvider.calendar.date(byAdding: .hour, value: 1, to: viewModel.startDate)!

        XCTAssertTrue(viewModel.hasValidDateRange)
        XCTAssertTrue(viewModel.hasValidInput)
    }

    func testViewModel_dateRange_allDay_sameDay_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = Date.make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = Date.make(year: 2025, month: 10, day: 25, at: .start)

        XCTAssertTrue(viewModel.hasValidDateRange)
        XCTAssertTrue(viewModel.hasValidInput)
    }

    func testViewModel_dateRange_allDay_endBeforeStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = Date.make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = Date.make(year: 2025, month: 10, day: 24, at: .start)

        XCTAssertFalse(viewModel.hasValidDateRange)
        XCTAssertFalse(viewModel.hasValidInput)
    }

    func testViewModel_isAllDay_toggleOn_stripsTimeAndFixesEnd() {

        let viewModel = EventEditorViewModel(
            startDate: Date.make(year: 2025, month: 10, day: 25, hour: 14, minute: 30),
            dateProvider: dateProvider
        )

        viewModel.endDate = Date.make(year: 2025, month: 10, day: 24, hour: 16)

        viewModel.isAllDay = true

        XCTAssertEqual(viewModel.startDate, Date.make(year: 2025, month: 10, day: 25, at: .start))
        XCTAssertEqual(viewModel.endDate, Date.make(year: 2025, month: 10, day: 25, at: .start))
    }

    func testViewModel_isAllDay_toggleOff_setsEndOneHourAfterStartWhenNeeded() {

        let viewModel = EventEditorViewModel(
            startDate: Date.make(year: 2025, month: 10, day: 25, hour: 14),
            dateProvider: dateProvider
        )

        viewModel.isAllDay = true
        viewModel.isAllDay = false

        let expectedEnd = dateProvider.calendar.date(byAdding: .hour, value: 1, to: viewModel.startDate)!
        XCTAssertEqual(viewModel.endDate, expectedEnd)
    }

    func testViewModel_saveEvent_withInvalidInput_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.saveEvent()
        XCTAssertNil(lastValue)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate
        viewModel.saveEvent()
        XCTAssertNil(lastValue)
    }

    func testViewModel_saveEvent_withValidInput() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let start = dateProvider.now
        let end = dateProvider.calendar.date(byAdding: .hour, value: 2, to: start)!

        let viewModel = EventEditorViewModel(
            startDate: .init(date: start),
            dateProvider: dateProvider,
            calendarService: calendarService
        )

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "  Team sync  "
        viewModel.endDate = end
        viewModel.location = "  Office  "
        viewModel.url = "https://example.com"
        viewModel.notes = "  Agenda  "
        viewModel.selectedCalendarId = "cal-1"
        viewModel.saveEvent()

        XCTAssertEqual(lastValue?.title, "Team sync")
        XCTAssertEqual(lastValue?.calendar, "cal-1")
        XCTAssertEqual(lastValue?.start, start)
        XCTAssertEqual(lastValue?.end, end)
        XCTAssertEqual(lastValue?.isAllDay, false)
        XCTAssertEqual(lastValue?.location, "Office")
        XCTAssertEqual(lastValue?.url?.absoluteString, "https://example.com")
        XCTAssertEqual(lastValue?.notes, "Agenda")
        XCTAssertNil(lastValue?.alertOffset)
    }

    func testViewModel_initialState_selectedAlertIsNone() {

        let viewModel = EventEditorViewModel(dateProvider: dateProvider)

        XCTAssertEqual(viewModel.selectedAlert, .none)
    }

    func testViewModel_saveEvent_withNoAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        XCTAssertNil(lastValue?.alertOffset)
    }

    func testViewModel_saveEvent_withAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .tenMinutesBefore
        viewModel.saveEvent()

        XCTAssertEqual(lastValue?.alertOffset, -600)
    }

    func testViewModel_saveEvent_withAtTimeOfEventAlert() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .atTimeOfEvent
        viewModel.saveEvent()

        XCTAssertEqual(lastValue?.alertOffset, 0)
    }

    func testViewModel_saveEvent_withError() {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        XCTAssertTrue(viewModel.isErrorVisible)
        XCTAssertEqual(viewModel.error?.localizedDescription, "Creation failed")

        viewModel.dismissError()
        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertNil(viewModel.error)
    }

    func testViewModel_saveEvent_withSuccess_shouldCloseWindow() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should close window")

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_saveEvent_withError_shouldNotCloseWindow() {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withInvalidInput_shouldCloseWindow() {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = EventEditorViewModel(dateProvider: dateProvider)

        viewModel.onCloseConfirmed = expectation.fulfill

        XCTAssertTrue(viewModel.requestWindowClose())
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withValidInput_shouldAskForConfirmation() {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let closeExpectation = expectation(description: "Should close window")

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"

        XCTAssertFalse(viewModel.requestWindowClose())
        XCTAssertTrue(viewModel.isCloseConfirmationVisible)

        wait(for: [notCloseExpectation], timeout: 0.1)

        viewModel.onCloseConfirmed = closeExpectation.fulfill
        viewModel.confirmClose()

        wait(for: [closeExpectation], timeout: 0.1)
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
    }

    func testViewModel_withCloseRequested_withInvalidDateRange_shouldAskForConfirmation() {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"
        viewModel.notes = "Agenda"
        viewModel.endDate = viewModel.startDate

        XCTAssertFalse(viewModel.hasValidInput)
        XCTAssertFalse(viewModel.requestWindowClose())
        XCTAssertTrue(viewModel.isCloseConfirmationVisible)

        wait(for: [notCloseExpectation], timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withNotesOnly_shouldAskForConfirmation() {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = EventEditorViewModel(dateProvider: dateProvider)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.notes = "Some notes"

        XCTAssertFalse(viewModel.requestWindowClose())
        XCTAssertTrue(viewModel.isCloseConfirmationVisible)

        wait(for: [notCloseExpectation], timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withLocationOnly_shouldAskForConfirmation() {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = EventEditorViewModel(dateProvider: dateProvider)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.location = "Office"

        XCTAssertFalse(viewModel.requestWindowClose())
        XCTAssertTrue(viewModel.isCloseConfirmationVisible)

        wait(for: [notCloseExpectation], timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withWhitespaceOnly_shouldCloseWindow() {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = EventEditorViewModel(dateProvider: dateProvider)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "   "
        viewModel.notes = "   "

        XCTAssertTrue(viewModel.requestWindowClose())
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_calendars_withDefault_shouldSelectDefaultCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-2"

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarId, "cal-2")
    }

    func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        XCTAssertEqual(viewModel.calendarSections.count, 2)
        XCTAssertEqual(viewModel.calendarSections[0].account.title, "Google")
        XCTAssertEqual(viewModel.calendarSections[1].account.title, "iCloud")
    }

    func testViewModel_saveEvent_shouldPassSelectedCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let viewModel = EventEditorViewModel(dateProvider: dateProvider, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveEvent()

        XCTAssertEqual(lastValue?.calendar, "cal-2")
    }
}

private class FailingEventCalendarService: MockCalendarServiceProvider {

    override func createEvent(
        title: String,
        calendar: String,
        start: Date,
        end: Date,
        isAllDay: Bool,
        location: String?,
        url: URL?,
        notes: String?,
        alertOffset: TimeInterval?
    ) -> Completable {
        .error(.unexpected("Creation failed"))
    }
}

private extension EventEditorViewModel {

    convenience init(
        startDate: Date = .now,
        dateProvider: DateProviding = MockDateProvider(),
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider()
    ) {
        self.init(
            startDate: .init(date: startDate),
            dateProvider: dateProvider,
            calendarService: calendarService
        )
    }
}
