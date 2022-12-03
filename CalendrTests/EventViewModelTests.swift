//
//  EventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 27/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class EventViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let popoverSettings = MockPopoverSettings()

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", type: .event(.pending), calendar: .make(color: .black))
        )

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.color, .black)
        XCTAssertEqual(viewModel.type, .event(.pending))
    }

    func testSubtitle_withExtraSpacesInLocation_withURLInLocation_shouldShowTrimmedLocation() {

        let viewModel = mock(
            event: .make(location: " \n Location https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "Location someurl.com")
    }

    func testSubtitle_withExtraSpacesInLocation_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " \n https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withEmptyLocation_withURL_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withEmptyLocation_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", notes: " \nSome \nnotes https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withLocation_withoutURL_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address")
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
    }

    func testSubtitle_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "https://someurl.com")
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withURL_withoutLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withURL_withLocation_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
    }

    func testSubtitle_withoutLocation_withoutURL_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(notes: "Some notes https://someurl.com")
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withoutLocation_withoutURL_withNotes_shouldShowNotes() {

        let viewModel = mock(
            event: .make(notes: "Some notes")
        )

        XCTAssertEqual(viewModel.subtitle, "Some notes")
    }

    func testSubtitle_withLocation_isAllDay_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address", isAllDay: true)
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
    }

    func testSubtitle_withURL_isAllDay_isNotBirthday_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "someurl.com")
    }

    func testSubtitle_withURL_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        XCTAssertEqual(viewModel.subtitle, "")
    }

    func testDuration_isAllDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "")
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "3:00-4:00 PM")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 2, hour: 0)
            )
        )

        XCTAssertEqual(viewModel.duration, "3:00 PM - 12:00 AM")
    }

    func testDuration_isMultiDay_isSameMonth_withTime() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3, hour: 0, minute: 1)
            )
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-01-03 00:01")
    }

    func testDuration_isMultiDay_isDifferentMonth_withTime() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3, hour: 0, minute: 1)
            )
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-02-03 00:01")
    }

    func testDuration_isMultiDay_isSameMonth_endsStartOfNextDay() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3)
            )
        )

        XCTAssertEqual(viewModel.duration, "January 1 - 2")
    }

    func testDuration_isMultiDay_isDifferentMonth_endsStartOfNextDay() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1 - Feb 2")
    }

    func testBarStyle() {

        XCTAssertEqual(mock(type: .birthday).barStyle, .filled)
        XCTAssertEqual(mock(type: .reminder).barStyle, .filled)
        XCTAssertEqual(mock(type: .event(.accepted)).barStyle, .filled)
        XCTAssertEqual(mock(type: .event(.pending)).barStyle, .filled)
        XCTAssertEqual(mock(type: .event(.declined)).barStyle, .filled)
        XCTAssertEqual(mock(type: .event(.maybe)).barStyle, .bordered)
    }

    func mock(type: EventType) -> EventViewModel { mock(event: .make(type: type)) }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            popoverSettings: popoverSettings,
            isShowingDetails: .dummy(),
            scheduler: MainScheduler.instance
        )
    }
}
