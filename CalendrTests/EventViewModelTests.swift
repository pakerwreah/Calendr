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

    let userDefaults = UserDefaults(suiteName: className())!

    lazy var settings = SettingsViewModel(userDefaults: userDefaults)

    private let dateProvider = MockDateProvider()

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

        XCTAssertEqual(viewModel.duration, "15:00 - 16:00")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 2, hour: 0)
        )

        XCTAssertEqual(viewModel.duration, "15:00 - 00:00")
    }

    func testDuration_isMultiDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 2, hour: 0, minute: 1)
        )

        XCTAssertEqual(viewModel.duration, "Start: 2021-01-01 15:00\nEnd:   2021-01-02 00:01")
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
