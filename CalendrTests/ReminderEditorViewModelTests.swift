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

        let calendarService = MockCalendarServiceProvider()
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
        XCTAssertEqual(lastValue?.date, dueDate)
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
}

private class FailingCalendarService: MockCalendarServiceProvider {

    override func createReminder(title: String, date: Date) -> Completable {
        return .error(.unexpected("Creation failed"))
    }
}

private extension ReminderEditorViewModel {

    convenience init(dueDate: Date = .now, calendarService: CalendarServiceProviding = MockCalendarServiceProvider()) {
        self.init(dueDate: .init(date: dueDate), calendarService: calendarService)
    }
}
