//
//  ReminderEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 25/10/2025.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class ReminderEditorViewModelTests {

    @Test func testDueDate() {

        let dateProvider = MockDateProvider()

        dateProvider.now = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30, second: 50)

        let dueDate = DueDate.withCurrentTime(
            at: .make(year: 2025, month: 10, day: 5, at: .start),
            adding: .init(hour: 5, minute: 10),
            using: dateProvider
        )

        #expect(dueDate.date == .make(year: 2025, month: 10, day: 5, hour: 15, minute: 40, second: 0))
    }

    @Test func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let dueDate = Date()

        let viewModel = makeViewModel(dueDate: dueDate, calendarService: calendarService)

        #expect(viewModel.title == "")
        #expect(viewModel.dueDate == dueDate)
        #expect(viewModel.error == nil)
        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.hasValidInput == false)
        #expect(viewModel.isCloseConfirmationVisible == false)
        #expect(viewModel.calendarSections.isEmpty)
        #expect(viewModel.selectedCalendarId == nil)
        #expect(viewModel.selectedCalendarColor == .clear)
    }

    @Test func testViewModel_validInput() {

        let viewModel = makeViewModel()

        #expect(viewModel.hasValidInput == false)

        viewModel.title = "   "

        #expect(viewModel.hasValidInput == false)

        viewModel.title = " . "

        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_saveReminder_withInvalidInput_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let dueDate = Date()

        let viewModel = makeViewModel(dueDate: dueDate, calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        #expect(viewModel.hasValidInput == false)

        viewModel.saveReminder()

        #expect(lastValue == nil)

        viewModel.title = "valid"
        viewModel.saveReminder()

        #expect(lastValue?.title == "valid")
        #expect(lastValue?.calendar == "cal-1")
        #expect(lastValue?.date == dueDate)
        #expect(lastValue?.isAllDay == false)
    }

    @Test func testViewModel_saveReminder_allDay() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]
        let dueDate = Date()

        let viewModel = makeViewModel(dueDate: dueDate, calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "valid"
        viewModel.isAllDay = true
        viewModel.saveReminder()

        #expect(lastValue?.title == "valid")
        #expect(lastValue?.calendar == "cal-1")
        #expect(lastValue?.date == dueDate)
        #expect(lastValue?.isAllDay == true)
    }

    @Test func testViewModel_saveReminder_withError() {

        let calendarService = FailingCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.error == nil)

        viewModel.title = "valid"
        viewModel.saveReminder()

        #expect(viewModel.isErrorVisible)
        #expect(viewModel.error?.localizedDescription == "Creation failed")

        viewModel.dismissError()

        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.error == nil)
    }

    @Test func testViewModel_saveReminder_withError_shouldNotCloseWindow() async {

        let calendarService = FailingCalendarService()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "valid"
        viewModel.saveReminder()

        #expect(viewModel.isErrorVisible)

        viewModel.dismissError()

        #expect(viewModel.isErrorVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_saveReminder_withSuccess_shouldCloseWindow() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should close window")

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "valid"
        viewModel.saveReminder()

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_saveReminder_withNoCalendar_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "valid"
        viewModel.saveReminder()

        #expect(lastValue == nil)
    }

    @Test func testViewModel_withCloseRequested_withInvalidInput_shouldCloseWindow() async {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = makeViewModel()

        // this should not be called because we should not ask for confirmation
        viewModel.onCloseConfirmed = expectation.fulfill

        // this is called by the view controller, which is the window delegate
        // the window will be closed automatically when the delegate returns true
        #expect(viewModel.requestWindowClose())

        #expect(viewModel.isCloseConfirmationVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_withCloseRequested_withValidInput_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let closeExpectation = expectation(description: "Should close window")

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "valid"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])

        viewModel.onCloseConfirmed = closeExpectation.fulfill
        viewModel.confirmClose()

        await fulfillment(of: [closeExpectation])

        #expect(viewModel.isCloseConfirmationVisible == false)
    }

    // MARK: - Calendar selection

    @Test func testViewModel_calendars_withDefault_shouldSelectDefaultCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-2"

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.selectedCalendarId == "cal-2")
    }

    @Test func testViewModel_calendars_withoutDefault_shouldSelectFirstCalendarFromPicker() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
            .make(id: "cal-4", account: "Google", title: "Reminders"),
        ]

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        let sections = calendarService.m_calendars.groupedByAccount()

        #expect(sections.first?.calendars.first?.id == "cal-4")
        #expect(viewModel.selectedCalendarId == "cal-4")
    }

    @Test func testViewModel_calendars_withInvalidDefault_shouldSelectFirstCalendarFromPicker() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
            .make(id: "cal-4", account: "Google", title: "Reminders"),
        ]
        calendarService.m_defaultCalendarId = "non-existent"

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        let sections = calendarService.m_calendars.groupedByAccount()

        #expect(sections.first?.calendars.first?.id == "cal-4")
        #expect(viewModel.selectedCalendarId == "cal-4")
    }

    @Test func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.calendarSections.count == 2)
        #expect(viewModel.calendarSections[0].account.title == "Google")
        #expect(viewModel.calendarSections[0].calendars.map(\.title) == ["Tasks"])
        #expect(viewModel.calendarSections[1].account.title == "iCloud")
        #expect(viewModel.calendarSections[1].calendars.map(\.title) == ["Personal", "Work"])
    }

    @Test func testViewModel_calendars_shouldSortOthersLast() {

        let othersAccount = Strings.Calendars.Source.others

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: othersAccount, title: "Local"),
            .make(id: "cal-2", account: "iCloud", title: "Work"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.calendarSections.count == 3)
        #expect(viewModel.calendarSections[0].account.title == "Google")
        #expect(viewModel.calendarSections[1].account.title == "iCloud")
        #expect(viewModel.calendarSections[2].account.title == othersAccount)
    }

    @Test func testViewModel_calendars_shouldSortCalendarsWithinSection() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Zebra"),
            .make(id: "cal-2", account: "iCloud", title: "Apple"),
            .make(id: "cal-3", account: "iCloud", title: "Mango"),
        ]

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.calendarSections.count == 1)
        #expect(viewModel.calendarSections[0].calendars.map(\.title) == ["Apple", "Mango", "Zebra"])
    }

    @Test func testViewModel_selectedCalendarColor() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work", color: .red),
            .make(id: "cal-2", title: "Personal", color: .blue),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.selectedCalendarColor == .red)

        viewModel.selectedCalendarId = "cal-2"

        #expect(viewModel.selectedCalendarColor == .blue)
    }

    @Test func testViewModel_selectedCalendarColor_withNoCalendars_shouldBeClear() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = []
        calendarService.m_defaultCalendarId = nil

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.selectedCalendarColor == .clear)
    }

    @Test func testViewModel_saveReminder_shouldPassSelectedCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let dueDate = Date()

        let viewModel = makeViewModel(dueDate: dueDate, calendarService: calendarService)

        var lastValue: CreateReminderArgs?
        _ = calendarService.spyCreateReminderObservable.bind { lastValue = $0 }

        viewModel.title = "My Reminder"
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveReminder()

        #expect(lastValue?.title == "My Reminder")
        #expect(lastValue?.calendar == "cal-2")
        #expect(lastValue?.date == dueDate)
        #expect(lastValue?.isAllDay == false)
    }

    @Test func testViewModel_calendars_empty_shouldHaveNoSections() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = []
        calendarService.m_defaultCalendarId = nil

        let viewModel = makeViewModel(dueDate: .now, calendarService: calendarService)

        #expect(viewModel.calendarSections.isEmpty)
        #expect(viewModel.selectedCalendarId == nil)
    }

    // MARK: - Factory

    func makeViewModel(
        dueDate: Date = .now,
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider()
    ) -> ReminderEditorViewModel {
        ReminderEditorViewModel(
            dueDate: .init(date: dueDate),
            calendarService: calendarService,
            scheduler: CurrentThreadScheduler.instance
        )
    }
}

private class FailingCalendarService: MockCalendarServiceProvider {

    override func createReminder(title: String, calendar: String, date: Date, isAllDay: Bool) -> Completable {
        return .error(.unexpected("Creation failed"))
    }
}
