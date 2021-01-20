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

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: className)
    }
}

private class MockCalendarServiceProvider: CalendarServiceProviding {

    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

    func calendars() -> [CalendarModel] {
        [
            .init(identifier: "1", account: "A1", title: "Calendar 1", color: .white),
            .init(identifier: "2", account: "A2", title: "Calendar 2", color: .black),
            .init(identifier: "3", account: "A3", title: "Calendar 3", color: .clear)
        ]
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> [EventModel] {
        return []
    }
}
