//
//  ReminderEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 25/10/2025.
//

import XCTest
import RxSwift
@testable import Calendr

class ReminderEditorViewModelTests: XCTestCase {

    func testDueDate() {

        let dateProvider = MockDateProvider()

        dateProvider.now = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30, second: 50)

        let dueDate = DueDate.withCurrentTime(
            at: .make(year: 2025, month: 10, day: 5, at: .start),
            adding: .init(hour: 5, minute: 10),
            using: dateProvider
        )

        XCTAssertEqual(dueDate.date, .make(year: 2025, month: 10, day: 5, hour: 15, minute: 40, second: 0))
    }

    func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.dueDate, dueDate)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertFalse(viewModel.hasValidInput)
        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
        XCTAssertTrue(viewModel.calendarSections.isEmpty)
        XCTAssertEqual(viewModel.selectedCalendarId, "")
        XCTAssertEqual(viewModel.selectedCalendarColor, .clear)
    }

    func testViewModel_validInput() {

        let viewModel = ReminderEditorViewModel()

        XCTAssertFalse(viewModel.hasValidInput)

        viewModel.title = "   "

        XCTAssertFalse(viewModel.hasValidInput)

        viewModel.title = " . "

        XCTAssertTrue(viewModel.hasValidInput)
    }

    func testViewModel_saveReminder_withInvalidInput_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider.withDefaultCalendar()
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        XCTAssertFalse(viewModel.hasValidInput)

        viewModel.saveReminder()

        XCTAssertNil(lastValue)

        viewModel.title = "valid"
        viewModel.saveReminder()

        XCTAssertEqual(lastValue?.title, "valid")
        XCTAssertEqual(lastValue?.calendar, MockCalendarServiceProvider.defaultCalendarId)
        XCTAssertEqual(lastValue?.date, dueDate)
        XCTAssertEqual(lastValue?.isAllDay, false)
    }

    func testViewModel_saveReminder_allDay() {

        let calendarService = MockCalendarServiceProvider.withDefaultCalendar()
        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "valid"
        viewModel.isAllDay = true
        viewModel.saveReminder()

        XCTAssertEqual(lastValue?.title, "valid")
        XCTAssertEqual(lastValue?.calendar, MockCalendarServiceProvider.defaultCalendarId)
        XCTAssertEqual(lastValue?.date, dueDate)
        XCTAssertEqual(lastValue?.isAllDay, true)
    }

    func testViewModel_saveReminder_withError() {

        let viewModel = ReminderEditorViewModel(calendarService: FailingCalendarService())

        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertNil(viewModel.error)

        viewModel.title = "valid"
        viewModel.saveReminder()

        XCTAssertTrue(viewModel.isErrorVisible)
        XCTAssertEqual(viewModel.error?.localizedDescription, "Creation failed")

        viewModel.dismissError()

        XCTAssertFalse(viewModel.isErrorVisible)
        XCTAssertNil(viewModel.error)
    }

    func testViewModel_saveReminder_withError_shouldNotCloseWindow() {

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = ReminderEditorViewModel(calendarService: FailingCalendarService())

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "valid"
        viewModel.saveReminder()

        XCTAssertTrue(viewModel.isErrorVisible)

        viewModel.dismissError()

        XCTAssertFalse(viewModel.isErrorVisible)

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_saveReminder_withSuccess_shouldCloseWindow() {

        let expectation = expectation(description: "Should close window")

        let viewModel = ReminderEditorViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "valid"
        viewModel.saveReminder()

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_saveReminder_withNoCalendar_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()
        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "valid"
        viewModel.saveReminder()

        XCTAssertNil(lastValue)
    }

    func testViewModel_withCloseRequested_withInvalidInput_shouldCloseWindow() {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = ReminderEditorViewModel()

        // this should not be called because we should not ask for confirmation
        viewModel.onCloseConfirmed = expectation.fulfill

        // this is called by the view controller, which is the window delegate
        // the window will be closed automatically when the delegate returns true
        XCTAssertTrue(viewModel.requestWindowClose())

        XCTAssertFalse(viewModel.isCloseConfirmationVisible)

        waitForExpectations(timeout: 0.1)
    }

    func testViewModel_withCloseRequested_withValidInput_shouldAskForConfirmation() {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let closeExpectation = expectation(description: "Should close window")

        let viewModel = ReminderEditorViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "valid"

        XCTAssertFalse(viewModel.requestWindowClose())
        XCTAssertTrue(viewModel.isCloseConfirmationVisible)

        wait(for: [notCloseExpectation], timeout: 0.1)

        viewModel.onCloseConfirmed = closeExpectation.fulfill
        viewModel.confirmClose()

        wait(for: [closeExpectation], timeout: 0.1)

        XCTAssertFalse(viewModel.isCloseConfirmationVisible)
    }

    // MARK: - Calendar selection

    func testViewModel_calendars_withDefault_shouldSelectDefaultCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultReminderCalendarId = "cal-2"

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarId, "cal-2")
    }

    func testViewModel_calendars_withoutDefault_shouldSelectFirstCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarId, "cal-1")
    }

    func testViewModel_calendars_withInvalidDefault_shouldSelectFirstCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultReminderCalendarId = "non-existent"

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarId, "cal-1")
    }

    func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.calendarSections.count, 2)
        XCTAssertEqual(viewModel.calendarSections[0].title, "Google")
        XCTAssertEqual(viewModel.calendarSections[0].calendars.map(\.id), ["cal-3"])
        XCTAssertEqual(viewModel.calendarSections[1].title, "iCloud")
        XCTAssertEqual(viewModel.calendarSections[1].calendars.map(\.id), ["cal-1", "cal-2"])
    }

    func testViewModel_calendars_shouldSortOthersLast() {

        let othersAccount = Strings.Calendars.Source.others

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", account: othersAccount, title: "Local"),
            .make(id: "cal-2", account: "iCloud", title: "Work"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.calendarSections.count, 3)
        XCTAssertEqual(viewModel.calendarSections[0].title, "Google")
        XCTAssertEqual(viewModel.calendarSections[1].title, "iCloud")
        XCTAssertEqual(viewModel.calendarSections[2].title, othersAccount)
    }

    func testViewModel_calendars_shouldSortCalendarsWithinSection() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", account: "iCloud", title: "Zebra"),
            .make(id: "cal-2", account: "iCloud", title: "Apple"),
            .make(id: "cal-3", account: "iCloud", title: "Mango"),
        ]

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.calendarSections.count, 1)
        XCTAssertEqual(viewModel.calendarSections[0].calendars.map(\.title), ["Apple", "Mango", "Zebra"])
    }

    func testViewModel_selectedCalendarColor() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", title: "Work", color: .red),
            .make(id: "cal-2", title: "Personal", color: .blue),
        ]
        calendarService.m_defaultReminderCalendarId = "cal-1"

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarColor, .red)

        viewModel.selectedCalendarId = "cal-2"

        XCTAssertEqual(viewModel.selectedCalendarColor, .blue)
    }

    func testViewModel_selectedCalendarColor_withNoCalendars_shouldBeClear() {

        let calendarService = MockCalendarServiceProvider()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertEqual(viewModel.selectedCalendarColor, .clear)
    }

    func testViewModel_saveReminder_shouldPassSelectedCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_reminderCalendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultReminderCalendarId = "cal-1"

        let dueDate = Date()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: dueDate), calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "My Reminder"
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveReminder()

        XCTAssertEqual(lastValue?.title, "My Reminder")
        XCTAssertEqual(lastValue?.calendar, "cal-2")
        XCTAssertEqual(lastValue?.date, dueDate)
        XCTAssertEqual(lastValue?.isAllDay, false)
    }

    func testViewModel_calendars_empty_shouldHaveNoSections() {

        let calendarService = MockCalendarServiceProvider()

        let viewModel = ReminderEditorViewModel(dueDate: .init(date: .now), calendarService: calendarService)

        XCTAssertTrue(viewModel.calendarSections.isEmpty)
        XCTAssertEqual(viewModel.selectedCalendarId, "")
    }
}

private class FailingCalendarService: MockCalendarServiceProvider {

    override init() {
        super.init()
        m_reminderCalendars = [.make(id: MockCalendarServiceProvider.defaultCalendarId)]
        m_defaultReminderCalendarId = MockCalendarServiceProvider.defaultCalendarId
    }

    override func createReminder(title: String, calendar: String, date: Date, isAllDay: Bool) -> Completable {
        return .error(.unexpected("Creation failed"))
    }
}

private extension MockCalendarServiceProvider {

    static let defaultCalendarId = "test-cal"

    static func withDefaultCalendar() -> MockCalendarServiceProvider {
        let mock = MockCalendarServiceProvider()
        mock.m_reminderCalendars = [.make(id: defaultCalendarId)]
        mock.m_defaultReminderCalendarId = defaultCalendarId
        return mock
    }
}

private extension ReminderEditorViewModel {

    convenience init(dueDate: Date = .now, calendarService: CalendarServiceProviding = MockCalendarServiceProvider.withDefaultCalendar()) {
        self.init(dueDate: .init(date: dueDate), calendarService: calendarService)
    }
}
