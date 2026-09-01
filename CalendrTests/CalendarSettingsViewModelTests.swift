//
//  CalendarSettingsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 01/08/2026.
//

import RxSwift
import Testing
@testable import Calendr

class CalendarSettingsViewModelTests {

    let localStorage = MockLocalStorageProvider()
    let workspace = MockWorkspaceServiceProvider()

    lazy var viewModel = CalendarSettingsViewModel(
        calendar: .make(id: "calendar"),
        workspace: workspace,
        localStorage: localStorage
    )

    @Test func testNextEventSettings() {

        #expect(viewModel.showNextEvent.lastValue() == true)
        #expect(viewModel.showNextEventTitle.lastValue() == true)

        viewModel.showNextEventObserver.onNext(false)
        viewModel.showNextEventTitleObserver.onNext(false)

        #expect(localStorage.silencedCalendars == ["calendar"])
        #expect(localStorage.hiddenEventStatusItemTitleCalendars == ["calendar"])
        #expect(viewModel.showNextEvent.lastValue() == false)
        #expect(viewModel.showNextEventTitle.lastValue() == false)

        viewModel.showNextEventObserver.onNext(true)
        viewModel.showNextEventTitleObserver.onNext(true)

        #expect(localStorage.silencedCalendars == [])
        #expect(localStorage.hiddenEventStatusItemTitleCalendars == [])
    }

    @Test func testHolidayCalendarSetting() {

        #expect(viewModel.isHolidayCalendar.lastValue() == false)

        viewModel.isHolidayCalendarObserver.onNext(true)

        #expect(localStorage.holidayCalendars == ["calendar"])
        #expect(viewModel.isHolidayCalendar.lastValue() == true)

        viewModel.isHolidayCalendarObserver.onNext(false)

        #expect(localStorage.holidayCalendars == [])
        #expect(viewModel.isHolidayCalendar.lastValue() == false)
    }
}
