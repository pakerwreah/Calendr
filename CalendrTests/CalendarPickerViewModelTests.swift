//
//  CalendarPickerViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 19/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class CalendarPickerViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let userDefaults = UserDefaults(suiteName: className())!
    let calendarService = MockCalendarServiceProvider()

    lazy var viewModel = CalendarPickerViewModel(
        calendarService: calendarService,
        userDefaults: userDefaults
    )

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)

        calendarService.m_calendars = [
            .make(id: "1", account: "A1", title: "Calendar 1", color: .white),
            .make(id: "2", account: "A2", title: "Calendar 2", color: .black),
            .make(id: "3", account: "A3", title: "Calendar 3", color: .clear)
        ]
    }

    func testCalendars() {

        var calendars: [String]?

        viewModel.calendars
            .bind { calendars = $0.map(\.id) }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(calendars, ["1", "2", "3"])
    }

    func testDefaultEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(userDefaults.disabledCalendars, [])

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])
    }

    func testDefaultNextEventCalendars() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(userDefaults.silencedCalendars, [])

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(nextEvent, ["1", "2", "3"])
    }

    func testEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        userDefaults.disabledCalendars = ["3"]

        XCTAssertEqual(enabled, ["1", "2"])
    }

    func testNextEventCalendars() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        userDefaults.silencedCalendars = ["3"]

        XCTAssertEqual(nextEvent, ["1", "2"])
    }

    func testToggleCalendar() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(userDefaults.disabledCalendars, ["2"])
        XCTAssertEqual(enabled, ["1", "3"])

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(userDefaults.disabledCalendars, [])
        XCTAssertEqual(enabled, ["1", "2", "3"])
    }

    func testSilenceCalendar() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleNextEvent.onNext("2")

        XCTAssertEqual(userDefaults.silencedCalendars, ["2"])
        XCTAssertEqual(nextEvent, ["1", "3"])

        viewModel.toggleNextEvent.onNext("2")

        XCTAssertEqual(userDefaults.silencedCalendars, [])
        XCTAssertEqual(nextEvent, ["1", "2", "3"])
    }

    func testNewCalendar_shouldBeEnabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        userDefaults.disabledCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["2", "3"])

        calendarService.m_calendars.append(.make(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["2", "3", "4"])
    }

    func testNewCalendar_shouldNotBeSilenced() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        userDefaults.silencedCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(nextEvent, ["2", "3"])

        calendarService.m_calendars.append(.make(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(nextEvent, ["2", "3", "4"])
    }

    func testRemoveCalendar_shouldRemoveEnabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["2", "3"])
    }

    func testRemoveCalendar_shouldRemoveDisabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        userDefaults.disabledCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["2", "3"])
        XCTAssertEqual(userDefaults.disabledCalendars, [])
    }

    func testRemoveCalendar_shouldRemoveSilenced() {

        var nextEvent: [String]?

        viewModel.nextEventCalendars
            .bind { nextEvent = $0 }
            .disposed(by: disposeBag)

        userDefaults.silencedCalendars = ["1"]

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(nextEvent, ["2", "3"])

        calendarService.m_calendars.removeFirst()

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(nextEvent, ["2", "3"])
        XCTAssertEqual(userDefaults.silencedCalendars, [])
    }
}
