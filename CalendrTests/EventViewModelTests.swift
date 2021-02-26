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
    let workspaceProvider = MockWorkspaceProvider()
    let settings = MockEventSettings()

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", isPending: true, calendar: .make(color: .black))
        )

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.color, .black)
        XCTAssertEqual(viewModel.isPending, true)
    }

    func testSubtitle_withLocation_withoutURL_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address", url: nil)
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
    }

    func testSubtitle_withURL_withoutLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: nil, url: URL(string: ".")!)
        )

        XCTAssertEqual(viewModel.subtitle, ".")
    }

    func testSubtitle_withURL_withLocation_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address", url: URL(string: ".")!)
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
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

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            workspaceProvider: workspaceProvider,
            settings: settings
        )
    }

    func mock(
        start: Date,
        end: Date,
        isAllDay: Bool = false
    ) -> EventViewModel {

        EventViewModel(
            event: .make(start: start, end: end, isAllDay: isAllDay),
            dateProvider: dateProvider,
            workspaceProvider: workspaceProvider,
            settings: settings
        )
    }
}
