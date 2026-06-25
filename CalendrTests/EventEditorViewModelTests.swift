//
//  EventEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventEditorViewModelTests {

    let dateProvider = MockDateProvider(
        now: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30)
    )

    @Test func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let start = dateProvider.now

        let viewModel = makeViewModel(
            startDate: start,
            calendarService: calendarService
        )

        #expect(viewModel.title == "")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0))
        #expect(viewModel.isAllDay == false)
        #expect(viewModel.location == "")
        #expect(viewModel.url == "")
        #expect(viewModel.notes == "")
        #expect(viewModel.error == nil)
        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.hasValidInput == false)
        #expect(viewModel.isCloseConfirmationVisible == false)
        #expect(viewModel.calendarSections.isEmpty)
        #expect(viewModel.selectedCalendarId == nil)
        #expect(viewModel.selectedCalendarColor == .clear)
    }

    @Test func testViewModel_validTitle() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.hasValidInput == false)

        viewModel.title = "   "
        #expect(viewModel.hasValidInput == false)

        viewModel.title = "Meeting"
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_timed_endEqualStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate

        #expect(viewModel.hasValidDateRange == false)
        #expect(viewModel.hasValidInput == false)
    }

    @Test func testViewModel_dateRange_timed_endAfterStart_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30),
            calendarService: calendarService
        )

        viewModel.title = "Meeting"
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_sameDay_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, at: .start)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_endBeforeStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = .make(year: 2025, month: 10, day: 24, at: .start)

        #expect(viewModel.hasValidDateRange == false)
        #expect(viewModel.hasValidInput == false)
    }

    @Test func testViewModel_isAllDay_toggleOn_stripsTimeAndFixesEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 14, minute: 30)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 24, hour: 16)

        viewModel.isAllDay = true

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))
    }

    @Test func testViewModel_isAllDay_toggleOff_setsEndOneHourAfterStartWhenNeeded() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 14)
        )

        viewModel.isAllDay = true
        viewModel.isAllDay = false

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 1, minute: 0))
    }

    @Test func testViewModel_saveEvent_withInvalidInput_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.saveEvent()
        #expect(lastValue == nil)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate
        viewModel.saveEvent()
        #expect(lastValue == nil)
    }

    @Test func testViewModel_saveEvent_withValidInput() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0)
        let end: Date = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 30)

        let viewModel = makeViewModel(startDate: start, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "  Team sync  "
        viewModel.endDate = end
        viewModel.location = "  Office  "
        viewModel.url = "https://example.com"
        viewModel.notes = "  Agenda  "
        viewModel.selectedCalendarId = "cal-1"
        viewModel.saveEvent()

        #expect(lastValue?.title == "Team sync")
        #expect(lastValue?.calendar == "cal-1")
        #expect(lastValue?.start == start)
        #expect(lastValue?.end == end)
        #expect(lastValue?.isAllDay == false)
        #expect(lastValue?.location == "Office")
        #expect(lastValue?.url?.absoluteString == "https://example.com")
        #expect(lastValue?.notes == "Agenda")
        #expect(lastValue?.alertOffset == nil)
        #expect(lastValue?.timeZone == dateProvider.calendar.timeZone)
    }

    @Test func testViewModel_initialState_selectedTimeZoneIsDateProviderTimeZone() {

        let timeZone = TimeZone(secondsFromGMT: -5 * 3600)!
        dateProvider.m_calendar = Calendar.gregorian.with(timeZone: timeZone)

        let viewModel = makeViewModel()

        #expect(viewModel.selectedTimeZoneIdentifier == timeZone.identifier)
    }

    @Test func testViewModel_saveEvent_passesSelectedTimeZone() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedTimeZoneIdentifier = "America/Sao_Paulo"
        viewModel.saveEvent()

        #expect(lastValue?.timeZone.identifier == "America/Sao_Paulo")
    }

    @Test func testViewModel_changingTimeZone_preservesWallClockTime() {

        let oldTimeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        dateProvider.m_calendar = Calendar.gregorian.with(timeZone: oldTimeZone)

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 14, minute: 30, timeZone: oldTimeZone)

        let viewModel = makeViewModel(startDate: start)

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: oldTimeZone))

        viewModel.selectedTimeZoneIdentifier = "UTC"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: .utc))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 16, minute: 0, timeZone: .utc))
    }

    @Test func testViewModel_init_roundsStartUpToNextHour() {

        let onTheHour: Date = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 0)
        let withMinutes: Date = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30)

        let onTheHourViewModel = makeViewModel(startDate: onTheHour)
        let withMinutesViewModel = makeViewModel(startDate: withMinutes)

        #expect(onTheHourViewModel.startDate == onTheHour)
        #expect(withMinutesViewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0))
    }

    @Test func testViewModel_changingEndDate_tracksDuration() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0)

        viewModel.startDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0))
    }

    @Test func testViewModel_changingEndDate_invalid_doesNotUpdateDuration() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0)
        viewModel.endDate = viewModel.startDate

        viewModel.startDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0))
    }

    @Test func testViewModel_isAllDay_changingStartDate_fixesInvalidEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 26, at: .start)

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_isAllDay_changingStartDate_keepsValidEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.isAllDay = true

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))

        viewModel.startDate = .make(year: 2025, month: 10, day: 26, at: .start)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_initialState_selectedAlertIsNone() {

        let viewModel = makeViewModel()

        #expect(viewModel.selectedAlert == .none)
    }

    @Test func testViewModel_saveEvent_withNoAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == nil)
    }

    @Test func testViewModel_saveEvent_withAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .tenMinutesBefore
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == -600)
    }

    @Test func testViewModel_saveEvent_withAtTimeOfEventAlert() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .atTimeOfEvent
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == 0)
    }

    @Test func testViewModel_saveEvent_withError() {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        #expect(viewModel.isErrorVisible)
        #expect(viewModel.error?.localizedDescription == "Creation failed")

        viewModel.dismissError()
        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.error == nil)
    }

    @Test func testViewModel_saveEvent_withSuccess_shouldCloseWindow() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should close window")

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_saveEvent_withError_shouldNotCloseWindow() async {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_withCloseRequested_withInvalidInput_shouldCloseWindow() async {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill

        #expect(viewModel.requestWindowClose())
        #expect(viewModel.isCloseConfirmationVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_withCloseRequested_withValidInput_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let closeExpectation = expectation(description: "Should close window")

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])

        viewModel.onCloseConfirmed = closeExpectation.fulfill
        viewModel.confirmClose()

        await fulfillment(of: [closeExpectation])
        #expect(viewModel.isCloseConfirmationVisible == false)
    }

    @Test func testViewModel_withCloseRequested_withInvalidDateRange_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"
        viewModel.notes = "Agenda"
        viewModel.endDate = viewModel.startDate

        #expect(viewModel.hasValidInput == false)
        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withNotesOnly_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.notes = "Some notes"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withLocationOnly_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.location = "Office"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withWhitespaceOnly_shouldCloseWindow() async {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "   "
        viewModel.notes = "   "

        #expect(viewModel.requestWindowClose())
        #expect(viewModel.isCloseConfirmationVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_calendars_withDefault_shouldSelectDefaultCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-2"

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.selectedCalendarId == "cal-2")
    }

    @Test func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.calendarSections.count == 2)
        #expect(viewModel.calendarSections[0].account.title == "Google")
        #expect(viewModel.calendarSections[1].account.title == "iCloud")
    }

    @Test func testViewModel_saveEvent_shouldPassSelectedCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveEvent()

        #expect(lastValue?.calendar == "cal-2")
    }

    // MARK: - Factory

    func makeViewModel(
        startDate: Date? = nil,
        dateProvider: DateProviding? = nil,
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider()
    ) -> EventEditorViewModel {
        EventEditorViewModel(
            startDate: .init(date: startDate ?? self.dateProvider.now),
            dateProvider: dateProvider ?? self.dateProvider,
            calendarService: calendarService,
            scheduler: CurrentThreadScheduler.instance
        )
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
        alertOffset: TimeInterval?,
        timeZone: TimeZone
    ) -> Completable {
        .error(.unexpected("Creation failed"))
    }
}
