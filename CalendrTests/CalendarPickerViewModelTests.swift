//
//  CalendarPickerViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 19/01/21.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class CalendarPickerViewModelTests {

    let disposeBag = DisposeBag()

    let localStorage = MockLocalStorageProvider()
    let calendarService = MockCalendarServiceProvider()

    lazy var viewModel = CalendarPickerViewModel(
        calendarService: calendarService,
        localStorage: localStorage
    )

    init() {

        localStorage.reset()

        calendarService.m_calendars = [
            .make(id: "1", account: "A1", title: "Calendar 1", color: .white),
            .make(id: "2", account: "A2", title: "Calendar 2", color: .black),
            .make(id: "3", account: "A3", title: "Calendar 3", color: .clear)
        ]
    }

    @Test func testCalendars() {

        var calendars: [String]?

        viewModel.calendars
            .bind { calendars = $0.map(\.id) }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        #expect(calendars == ["1", "2", "3"])
    }

    @Test func testDefaultEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        #expect(localStorage.disabledCalendars == [])

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["1", "2", "3"])
    }

    @Test func testDefaultNextEventCalendars() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        #expect(localStorage.silencedCalendars == [])

        calendarService.changeObserver.onNext(())

        #expect(nextEvent == ["1", "2", "3"])
    }

    @Test func testEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        localStorage.disabledCalendars = ["3"]

        #expect(enabled == ["1", "2"])
    }

    @Test func testNextEventCalendars() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        localStorage.silencedCalendars = ["3"]

        #expect(nextEvent == ["1", "2"])
    }

    @Test func testToggleCalendar() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleCalendar.onNext("2")

        #expect(localStorage.disabledCalendars == ["2"])
        #expect(enabled == ["1", "3"])

        viewModel.toggleCalendar.onNext("2")

        #expect(localStorage.disabledCalendars == [])
        #expect(enabled == ["1", "2", "3"])
    }

    @Test func testSilenceCalendar() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleNextEvent.onNext("2")

        #expect(localStorage.silencedCalendars == ["2"])
        #expect(nextEvent == ["1", "3"])

        viewModel.toggleNextEvent.onNext("2")

        #expect(localStorage.silencedCalendars == [])
        #expect(nextEvent == ["1", "2", "3"])
    }

    @Test func testNewCalendar_shouldBeEnabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        localStorage.disabledCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["2", "3"])

        calendarService.m_calendars.append(.make(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["2", "3", "4"])
    }

    @Test func testNewCalendar_shouldNotBeSilenced() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        localStorage.silencedCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        #expect(nextEvent == ["2", "3"])

        calendarService.m_calendars.append(.make(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        #expect(nextEvent == ["2", "3", "4"])
    }

    @Test func testRemoveCalendar_shouldRemoveEnabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["1", "2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["2", "3"])
    }

    @Test func testRemoveCalendar_shouldRemoveDisabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        localStorage.disabledCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        #expect(enabled == ["2", "3"])
        #expect(localStorage.disabledCalendars == [])
    }

    @Test func testRemoveCalendar_shouldRemoveSilenced() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        localStorage.silencedCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        #expect(nextEvent == ["2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        #expect(nextEvent == ["2", "3"])
        #expect(localStorage.silencedCalendars == [])
    }
}
