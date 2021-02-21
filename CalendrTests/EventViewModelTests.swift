//
//  EventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 27/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class EventViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()

    let userDefaults = UserDefaults(suiteName: className())!

    let notificationCenter = NotificationCenter()

    lazy var settings = SettingsViewModel(
        dateProvider: dateProvider,
        userDefaults: userDefaults,
        notificationCenter: notificationCenter
    )

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testBasicInfo() {

        let calendar = CalendarModel(identifier: "", account: "", title: "", color: .black)
        let event: EventModel = .make(start: Date(), end: Date(), title: "Title", isPending: true, calendar: calendar)
        let viewModel = EventViewModel(event: event, dateProvider: dateProvider, settings: settings)

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.color, .black)
        XCTAssertEqual(viewModel.isPending, true)
    }

    func testDuration_isAllDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 1),
            isAllDay: true
        )

        XCTAssertEqual(viewModel.duration, "")
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 1, hour: 16)
        )

        XCTAssertEqual(viewModel.duration, "3:00 PM - 4:00 PM")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 2, hour: 0)
        )

        XCTAssertEqual(viewModel.duration, "3:00 PM - 12:00 AM")
    }

    func testDuration_isMultiDay_isSameMonth_withTime() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 3, hour: 0, minute: 1)
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-01-03 00:01")
    }

    func testDuration_isMultiDay_isDifferentMonth_withTime() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 2, day: 3, hour: 0, minute: 1)
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-02-03 00:01")
    }

    func testDuration_isMultiDay_isSameMonth_endsStartOfNextDay() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 3)
        )

        XCTAssertEqual(viewModel.duration, "January 1 - 2")
    }

    func testDuration_isMultiDay_isDifferentMonth_endsStartOfNextDay() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 2, day: 3)
        )

        XCTAssertEqual(viewModel.duration, "Jan 1 - Feb 2")
    }

    func mock(
        start: Date,
        end: Date,
        isAllDay: Bool = false
    ) -> EventViewModel {

        EventViewModel(
            event: .make(start: start, end: end, isAllDay: isAllDay),
            dateProvider: dateProvider,
            settings: settings
        )
    }
}
