//
//  EventViewModelLinkTests.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventViewModelLinkTests {

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventSettings()
    let localStorage = MockLocalStorageProvider()

    @Test func testLink_withRegularLocation_withoutURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(location: "some location")
        )

        #expect(viewModel.link == nil)
    }

    @Test func testLink_withRegularLocation_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "invalidurl")!
            )
        )

        #expect(viewModel.link == nil)
    }

    @Test func testLink_withRegularLocation_withValidURL_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(
                location: "some location",
                url: URL(string: "https://someurl.com")!
            )
        )

        let link = try #require(viewModel.link)

        #expect(link.isMeeting == false)
        #expect(link.url.absoluteString == "https://someurl.com")
    }

    @Test func testLink_withUrlLocation_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(location: "https://someurl.com")
        )

        let link = try #require(viewModel.link)

        #expect(link.isMeeting == false)
        #expect(link.url.absoluteString == "https://someurl.com")
    }

    @Test func testLink_withInvalidURL_shouldNotShowLinkButton() {

        let viewModel = mock(
            event: .make(url: URL(string: "invalidurl")!)
        )

        #expect(viewModel.link == nil)
    }

    @Test func testLink_withValidURL_shouldShowLinkButton() throws {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        let link = try #require(viewModel.link)

        #expect(link.isMeeting == false)
        #expect(link.url.absoluteString == "https://someurl.com")
    }

    @Test func testLink_withZoomURL_withZoomNotInstalled() throws {

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withZoomURL_withZoomInstalled() throws {

        workspace.m_urlForApplicationToOpenURL = URL(string: "dummy")

        let httpLink = "https://something.zoom.us/j/0000000000?pwd=xxxxxxxxxx"
        let appLink = "zoommtg://something.zoom.us/join?confno=0000000000&pwd=xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == appLink)
    }

    @Test func testLink_withTeamsURL_withTeamsNotInstalled() throws {

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withTeamsURL_withTeamsInstalled() throws {

        workspace.m_urlForApplicationToOpenURL = URL(string: "dummy")

        let httpLink = "https://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"
        let appLink = "msteams://teams.microsoft.com/l/meetup-join/xxxxxxxxxx"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == appLink)
    }

    @Test func testLink_withFacetimeURL() throws {

        let httpLink = "https://facetime.apple.com"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withGoogleMeetURL() throws {

        let httpLink = "https://meet.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withGoogleHangoutsURL() throws {

        let httpLink = "https://hangouts.google.com"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withWebexMeetingURL() throws {

        let httpLink = "https://mycompany.webex.com/mycompany/j.php?MTID=12345"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    @Test func testLink_withWebexPersonalURL() throws {

        let httpLink = "https://mycompany.webex.com/meet/name"

        let viewModel = mock(event: .make(location: httpLink))

        let link = try #require(viewModel.link)

        #expect(link.isMeeting)
        #expect(link.url.absoluteString == httpLink)
    }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            source: .calendar,
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            localStorage: localStorage,
            settings: settings,
            isShowingDetailsModal: .dummy(),
            callback: .dummy(),
            isTodaySelected: true,
            scheduler: MainScheduler.instance
        )
    }
}
