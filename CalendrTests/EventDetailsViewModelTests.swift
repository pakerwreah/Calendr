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
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventDetailsSettings()

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
                type: .reminder(completed: false)
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

    func testSkip_withSouceList_shouldNotShowSkip() {
        
        let viewModel = mock(
            event: .make(type: .event(.unknown)),
            source: .list
        )
        
        XCTAssertFalse(viewModel.showSkip)
    }

    func testSkip_withSouceMenubar_shouldShowSkip() {
        
        let viewModel = mock(
            event: .make(type: .event(.unknown)),
            source: .menubar
        )
        
        XCTAssertTrue(viewModel.showSkip)
    }

    func testSkip_withSouceMenubar_isBirthday_shouldShowSkip() {
        
        let viewModel = mock(
            event: .make(type: .birthday),
            source: .menubar
        )
        
        XCTAssertTrue(viewModel.showSkip)
    }

    func testSkip_withSouceMenubar_isReminder_shouldNotShowSkip() {
        
        let viewModel = mock(
            event: .make(type: .reminder(completed: false)),
            source: .list
        )
        
        XCTAssertFalse(viewModel.showSkip)
    }

    func testSkip_shouldTriggerClose() {

        var action: ContextCallbackAction?

        let viewModel = mock(
            event: .make(type: .event(.unknown)),
            source: .menubar
        ) {
            action = $0
        }

        XCTAssert(viewModel.showSkip)

        let expectation = expectation(description: "Close")

        viewModel.close
            .subscribe(onCompleted: expectation.fulfill)
            .disposed(by: disposeBag)

        viewModel.skipTapped.onNext(())

        waitForExpectations(timeout: 1)

        XCTAssertEqual(action, .event(.skip))
    }

    func testStatusChange_shouldTriggerClose() {

        var action: ContextCallbackAction?

        let viewModel = mock(
            event: .make(type: .event(.pending)),
            source: .menubar
        ) {
            action = $0
        }

        let expectation = expectation(description: "Close")

        viewModel.close
            .subscribe(onCompleted: expectation.fulfill)
            .disposed(by: disposeBag)

        let contextMenu = viewModel.makeContextMenuViewModel() as? EventOptionsViewModel

        XCTAssertNotNil(contextMenu)

        contextMenu?.triggerAction(.status(.accept))

        waitForExpectations(timeout: 1)

        XCTAssertEqual(action, .event(.status(.accept)))
    }

    func testBrowserOptions() {

        workspace.m_urlForApplicationToOpenURL = makeUrl("Default")
        workspace.m_urlForApplicationToOpenContentType = makeUrl("Default")

        XCTAssertEqual(workspace.urlForDefaultBrowserApplication(), makeUrl("Default"))

        workspace.m_urlsForApplicationsToOpenURL = [makeUrl("Browser 2"), makeUrl("Browser 1"), makeUrl("Default"), makeUrl("Browser 3")]
        workspace.m_urlsForApplicationsToOpenContentType = [makeUrl("Browser 2"), makeUrl("Browser 1"), makeUrl("Default"), makeUrl("Browser 3"), makeUrl("Not a real browser 4")]

        let urlsForBrowsers = workspace.urlsForBrowsersApplications()

        let expectedURLs = [makeUrl("Browser 2"), makeUrl("Browser 1"), makeUrl("Default"), makeUrl("Browser 3")]

        XCTAssertEqual(urlsForBrowsers.count, 4)
        XCTAssert(expectedURLs.allSatisfy(urlsForBrowsers.contains))

        let viewModel = mock(event: .make(location: "https://example.com"))

        let sortedBrowserNames = viewModel.browserOptions.map(\.name)

        XCTAssertEqual(sortedBrowserNames, ["Default", "Browser 1", "Browser 2", "Browser 3"])

    }

    private class MockedURL: NSURL, @unchecked Sendable {

        var resourceValues: [URLResourceKey : Any] = [:]

        override func resourceValues(forKeys keys: [URLResourceKey]) throws -> [URLResourceKey : Any] {
            return resourceValues
        }
    }

    func makeUrl(_ name: String) -> URL {
        let path = "/path/Applications/\(name).app".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        let url = MockedURL(string: path)!
        url.resourceValues[.nameKey] = "\(name).app"
        url.resourceValues[.effectiveIconKey] = NSImage()
        return url as URL
    }

    func mock(event: EventModel, source: EventDetailsSource = .list, callback: @escaping (ContextCallbackAction?) -> Void = { _ in }) -> EventDetailsViewModel {

        EventDetailsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: .init(),
            settings: settings,
            isShowingObserver: .dummy(),
            isInProgress: .just(false),
            source: source,
            callback: .init { callback($0.element) }
        )
    }
}
