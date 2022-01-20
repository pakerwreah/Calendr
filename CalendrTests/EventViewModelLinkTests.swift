//
//  EventViewModelLinkTests.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import XCTest
@testable import Calendr

class EventViewModelLinkTests: XCTestCase {

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockPopoverSettings()

    func testLink_withRegularLocation_withoutURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(location: "some location")
        )

        XCTAssertNil(viewModel.linkURL)
    }

    func testLink_withRegularLocation_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "invalidurl")!
            )
        )

        XCTAssertNil(viewModel.linkURL)
    }

    func testLink_withRegularLocation_withValidURL_shouldShowLinkButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "https://someurl.com")!
            )
        )

        XCTAssertFalse(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withUrlLocation_shouldShowLinkButton() {

        let viewModel = mock(
            event: .make(location: "https://someurl.com")
        )

        XCTAssertFalse(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "invalidurl")!)
        )

        XCTAssertNil(viewModel.linkURL)
    }

    func testLink_withValidURL_shouldShowLinkButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertFalse(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withZoomURL_withZoomNotInstalled() {

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, httpLink)
    }

    func testLink_withZoomURL_withZoomInstalled() {

        workspace.m_supportsScheme = true

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"
        let appLink = "zoommtg://something.zoom.us/join?confno=0000000000&pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, appLink)
    }

    func testLink_withTeamsURL_withTeamsNotInstalled() {

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, httpLink)
    }

    func testLink_withTeamsURL_withTeamsInstalled() {

        workspace.m_supportsScheme = true

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"
        let appLink = "msteams://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, appLink)
    }

    func testLink_withGoogleMeetURL() {

        let httpLink = "https://meet.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, httpLink)
    }

    func testLink_withGoogleHangoutsURL() {

        let httpLink = "https://hangouts.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertTrue(viewModel.isMeeting)
        XCTAssertEqual(viewModel.linkURL?.absoluteString, httpLink)
    }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            settings: settings
        )
    }
}
