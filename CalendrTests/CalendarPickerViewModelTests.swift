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

    private let calendarService = MockCalendarServiceProvider()

    lazy var viewModel = CalendarPickerViewModel(
        calendarService: calendarService,
        userDefaults: userDefaults
    )

    var enabledCalendars: [String]? {
        userDefaults.stringArray(forKey: Prefs.enabledCalendars)
    }

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)

        calendarService.m_calendars = [
            .init(identifier: "1", account: "A1", title: "Calendar 1", color: .white),
            .init(identifier: "2", account: "A2", title: "Calendar 2", color: .black),
            .init(identifier: "3", account: "A3", title: "Calendar 3", color: .clear)
        ]
    }

    func testCalendars() {

        var calendars: [String]?

        viewModel.calendars
            .bind { calendars = $0.map(\.identifier) }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(calendars, ["1", "2", "3"])
    }

    func testDefaultEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        XCTAssertNil(enabledCalendars)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabledCalendars, enabled)
        XCTAssertEqual(enabled, ["1", "2", "3"])
    }

    func testEnabledCalendars() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        userDefaults.setValue(["1", "2"], forKey: Prefs.enabledCalendars)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2"])
    }

    func testToggleCalendar() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(enabledCalendars, enabled)
        XCTAssertEqual(enabled, ["1", "3"])

        viewModel.toggleCalendar.onNext("2")

        XCTAssertEqual(enabledCalendars, enabled)
        XCTAssertEqual(enabled, ["1", "3", "2"])
    }

    func testNewCalendar_shouldBeDisabled() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        XCTAssertEqual(enabled, ["1", "2", "3"])

        calendarService.m_calendars.append(.init(identifier: "4", account: "", title: "", color: .clear))

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

    func testToggleCalendar_ignoresOnCompleted() {

        var enabled: [String]?

        viewModel.enabledCalendars
            .bind { enabled = $0 }
            .disposed(by: disposeBag)

        calendarService.changeObserver.onNext(())

        viewModel.toggleCalendar.onCompleted()

        viewModel.toggleCalendar.onNext("2")
        XCTAssertEqual(enabled, ["1", "3"])
    }
}
