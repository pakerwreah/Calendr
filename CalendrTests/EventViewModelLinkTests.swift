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
    let workspaceProvider = MockWorkspaceProvider()

    func testLink_withRegularLocation_withoutURL_shouldNotShowVideoButton() {

        let viewModel = mock(
            event: .make(location: "some location")
        )

        XCTAssertNil(viewModel.videoURL)
    }

    func testLink_withRegularLocation_withInvalidURL_shouldNotShowVideoButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "invalidurl")!
            )
        )

        XCTAssertNil(viewModel.videoURL)
    }

    func testLink_withRegularLocation_withValidURL_shouldShowVideoButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "https://someurl.com")!
            )
        )

        XCTAssertEqual(viewModel.videoURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withUrlLocation_shouldShowVideoButton() {

        let viewModel = mock(
            event: .make(location: "https://someurl.com")
        )

        XCTAssertEqual(viewModel.videoURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withInvalidURL_shouldNotShowVideoButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "invalidurl")!)
        )

        XCTAssertNil(viewModel.videoURL)
    }

    func testLink_withValidURL_shouldShowVideoButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.videoURL?.absoluteString, "https://someurl.com")
    }

    func testLink_withVideoURL_withAppNotInstalled() {

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertEqual(viewModel.videoURL?.absoluteString, httpLink)
    }

    func testLink_withZoomURL_withZoomInstalled() {

        workspaceProvider.m_supportsSchema = true

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"
        let appLink = "zoommtg://something.zoom.us/join?confno=0000000000&pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertEqual(viewModel.videoURL?.absoluteString, appLink)
    }

    func testLink_withTeamsURL_withTeamsInstalled() {

        workspaceProvider.m_supportsSchema = true

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"
        let appLink = "msteams://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        XCTAssertEqual(viewModel.videoURL?.absoluteString, appLink)
    }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            workspaceProvider: workspaceProvider
        )
    }
}
