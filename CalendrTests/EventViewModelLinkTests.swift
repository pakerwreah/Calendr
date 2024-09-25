//
//  EventViewModelLinkTests.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class EventViewModelLinkTests: XCTestCase {

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventDetailsSettings()

    func testLink_withRegularLocation_withoutURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(location: "some location")
        )

        XCTAssertNil(viewModel.link)
    }

    func testLink_withRegularLocation_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "invalidurl")!
            )
        )

        XCTAssertNil(viewModel.link)
    }

    func testLink_withRegularLocation_withValidURL_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "https://someurl.com")!
            )
        )

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertFalse(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, "https://someurl.com")
    }

    func testLink_withUrlLocation_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(location: "https://someurl.com")
        )

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertFalse(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, "https://someurl.com")
    }

    func testLink_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "invalidurl")!)
        )

        XCTAssertNil(viewModel.link)
    }

    func testLink_withValidURL_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertFalse(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, "https://someurl.com")
    }

    func testLink_withZoomURL_withZoomNotInstalled() throws {

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, httpLink)
    }

    func testLink_withZoomURL_withZoomInstalled() throws {

        workspace.m_urlForApplication = URL(string: "dummy")

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"
        let appLink = "zoommtg://something.zoom.us/join?confno=0000000000&pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, appLink)
    }

    func testLink_withTeamsURL_withTeamsNotInstalled() throws {

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, httpLink)
    }

    func testLink_withTeamsURL_withTeamsInstalled() throws {

        workspace.m_urlForApplication = URL(string: "dummy")

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"
        let appLink = "msteams://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, appLink)
    }

    func testLink_withGoogleMeetURL() throws {

        let httpLink = "https://meet.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, httpLink)
    }

    func testLink_withGoogleHangoutsURL() throws {

        let httpLink = "https://hangouts.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try XCTUnwrap(viewModel.link)

        XCTAssertTrue(link.isMeeting)
        XCTAssertEqual(link.url.absoluteString, httpLink)
    }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: .init(),
            settings: settings,
            isShowingDetails: .dummy(),
            isTodaySelected: true,
            scheduler: MainScheduler.instance
        )
    }
}
