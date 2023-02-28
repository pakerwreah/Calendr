//
//  EventDetailsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 11/04/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class EventDetailsViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let popoverSettings = MockPopoverSettings()

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", location: "Location", notes: "Notes")
        )

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.location, "Location")
        XCTAssertEqual(viewModel.notes, "Notes")
    }

    func testDetails_withUrl_isNotBirthday_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.url, "https://someurl.com")
    }

    func testDetails_withUrl_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        XCTAssertEqual(viewModel.url, "")
    }

    func testDuration_isAllDay_isSingleDay_shouldShowOnlyDate() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021")
    }

    func testDuration_isAllDay_isMultiDay_shouldShowDateRange() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1 - 2, 2021")
    }

    func testDuration_isReminder_shouldShowOnlyStart() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                type: .reminder
            )
        )

        if #available(macOS 13, *) {
            XCTAssertEqual(viewModel.duration, "Jan 1, 2021 at 10:00 AM")
        } else {
            XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 AM")
        }
    }

    func testDuration_isMultiDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2, hour: 20)
            )
        )

        if #available(macOS 13, *) {
            XCTAssertEqual(viewModel.duration, "Jan 1, 2021 at 10:00 AM - Jan 2, 2021 at 8:00 PM")
        } else {
            XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 AM - Jan 2, 2021, 8:00 PM")
        }
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 3:00 - 4:00 PM")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 - 12:00 AM")
    }

    func testParticipants_shouldReturnCorrectOrder() {

        let viewModel = mock(
            event: .make(
                participants: [
                    .make(name: "c"),
                    .make(name: "b"),
                    .make(name: "me", isCurrentUser: true),
                    .make(name: "organizer", isOrganizer: true),
                    .make(name: "a"),
                ]
            )
        )

        XCTAssertEqual(viewModel.participants.map(\.name), ["organizer", "me", "a", "b", "c"])
    }

    func mock(event: EventModel) -> EventDetailsViewModel {

        EventDetailsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            popoverSettings: popoverSettings,
            isShowingObserver: .dummy(),
            isInProgress: .just(false)
        )
    }
}
