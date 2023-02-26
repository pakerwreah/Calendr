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
            .init(id: "1", account: "A1", title: "Calendar 1", color: .white),
            .init(id: "2", account: "A2", title: "Calendar 2", color: .black),
            .init(id: "3", account: "A3", title: "Calendar 3", color: .clear)
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

        XCTAssertNil(userDefaults.enabledCalendars)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])
    }

    func testEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        userDefaults.enabledCalendars = ["1", "2"]

        XCTAssertEqual(enabled, ["1", "2"])
    }

    func testToggleCalendar() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(userDefaults.enabledCalendars, enabled)
        XCTAssertEqual(enabled, ["1", "3"])

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(userDefaults.enabledCalendars, enabled)
        XCTAssertEqual(enabled, ["1", "3", "2"])
    }

    func testNewCalendar_shouldBeEnabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])

        calendarService.m_calendars.append(.init(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3", "4"])
    }

    func testNewCalendar_afterSelectingCalendars_shouldBeDisabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])

        userDefaults.enabledCalendars = ["1", "2", "3"]

        calendarService.m_calendars.append(.init(id: "4", account: "", title: "", color: .clear))

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])
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
}
