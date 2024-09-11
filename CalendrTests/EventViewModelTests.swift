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
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventDetailsSettings()

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", type: .event(.pending), calendar: .make(color: .black))
        )

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.color, .black)
        XCTAssertEqual(viewModel.type, .event(.pending))
    }

    func testSubtitle_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Location https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withExtraSpacesInLocation_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " \n https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withEmptyLocation_withURL_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withEmptyLocation_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", notes: " \nSome \nnotes https://someurl.com ")
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withLocation_withoutURL_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address")
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
    }

    func testSubtitle_withURL_withoutLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withURL_withLocation_shouldShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Some address", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "Some address")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withURL_withDifferentDomainInLocation_shouldShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Join at someotherurl.com", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "Join at someotherurl.com")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withURL_withSameDomainInLocation_shouldNotShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Join at someurl.com", url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withoutLocation_withoutURL_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(notes: "Some notes https://someurl.com")
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withoutLocation_withoutURL_withNotes_shouldShowNotes() {

        let viewModel = mock(
            event: .make(notes: "Some notes")
        )

        XCTAssertEqual(viewModel.subtitle, "Some notes")
    }

    func testSubtitle_withoutLocation_withoutURL_withNotesStartingWithTitle_shouldNotShowNotes() {

        let viewModel = mock(
            event: .make(title: "Title", notes: "Title some notes")
        )

        XCTAssertEqual(viewModel.subtitle, "")
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

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.subtitleLink, "someurl.com")
    }

    func testSubtitle_withURL_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertNil(viewModel.subtitleLink)
    }

    func testDuration_isAllDay_isSingleDay_shouldNotShowDuration() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "")
    }

    func testDuration_isAllDay_isMultiDay_shouldShowDuration() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2, at: .end),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "January 1 - 2")
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "3:00 - 4:00 PM")
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

        dateProvider.m_calendar = .gregorian.with(timeZone: .utc)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3, hour: 0, minute: 1)
            )
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-01-03 00:01")
    }

    func testDuration_isMultiDay_isDifferentMonth_withTime() {

        dateProvider.m_calendar = .iso8601

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3, hour: 0, minute: 1)
            )
        )

        XCTAssertEqual(viewModel.duration, "2021-01-01 00:00\n2021-02-03 00:01")
    }

    func testDuration_isMultiDay_isSameMonth_endsStartOfNextDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3)
            )
        )

        XCTAssertEqual(viewModel.duration, "January 1 - 2")
    }

    func testDuration_isMultiDay_isDifferentMonth_endsStartOfNextDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1 - Feb 2")
    }

    func testDuration_isSameDay_withDifferentTimeZone() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16),
                timeZone: .init(abbreviation: "GMT-3")
            )
        )

        XCTAssertEqual(viewModel.duration, "12:00 - 1:00 PM (GMT-3)")
    }

    func testDuration_isSameDay_isMeeting_withDifferentTimeZone() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16),
                participants: [.make()],
                timeZone: .init(abbreviation: "GMT-3")
            )
        )

        XCTAssertEqual(viewModel.duration, "3:00 - 4:00 PM")
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
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            settings: settings,
            isShowingDetails: .dummy(),
            isTodaySelected: true,
            scheduler: MainScheduler.instance
        )
    }
}
