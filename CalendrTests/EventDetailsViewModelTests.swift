//
//  EventDetailsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 11/04/2021.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class EventDetailsViewModelTests {

    let disposeBag = DisposeBag()

    let localStorage = MockLocalStorageProvider()
    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    lazy var workspace = MockWorkspaceServiceProvider(localStorage: localStorage)
    let settings = MockEventSettings()
    let scheduler = HistoricalScheduler()

    init() {

        localStorage.reset()

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    @Test func testIsInProgress() {

        let event = EventModel.make(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 2)
        )
        let duration = Int(event.start.distance(to: event.end))

        dateProvider.now = event.start - 1

        let viewModel = mock(event: event)

        var isInProgress: Bool?
        viewModel.isInProgress.bind {
            #expect(isInProgress != $0)
            isInProgress = $0
        }
        .disposed(by: disposeBag)

        #expect(isInProgress == false)

        dateProvider.add(1, .second)
        scheduler.advance(1, .second)

        #expect(isInProgress == true)

        dateProvider.now = event.end
        scheduler.advance(.seconds(duration))

        #expect(isInProgress == false)
    }

    @Test func testIsInProgress_isAlreadyInProgress() {

        let event = EventModel.make(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 2)
        )

        let duration = Int(event.start.distance(to: event.end))

        dateProvider.now = event.start

        let viewModel = mock(event: event)

        var isInProgress: Bool?
        viewModel.isInProgress.bind {
            #expect(isInProgress != $0)
            isInProgress = $0
        }
        .disposed(by: disposeBag)

        #expect(isInProgress == true)

        dateProvider.add(1, .second)
        scheduler.advance(1, .second)

        #expect(isInProgress == true)

        dateProvider.now = event.end
        scheduler.advance(.seconds(duration))

        #expect(isInProgress == false)
    }

    @Test func testIsInProgress_hasAlreadyEnded() {

        let event = EventModel.make(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 2)
        )

        dateProvider.now = event.end

        let viewModel = mock(event: event)

        var isInProgress: Bool?
        viewModel.isInProgress.bind {
            #expect(isInProgress != $0)
            isInProgress = $0
        }
        .disposed(by: disposeBag)

        #expect(isInProgress == false)

        dateProvider.add(1, .second)
        scheduler.advance(1, .second)

        #expect(isInProgress == false)
    }

    @Test func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", location: "Location", notes: "Notes")
        )

        #expect(viewModel.title == "Title")
        #expect(viewModel.location == "Location")
        #expect(viewModel.notes == "Notes")
    }

    @Test func testCanShowMap_showMapDisabled_shouldBeFalse() {

        settings.toggleShowMap.onNext(false)

        let viewModel = mock(
            event: .make(location: "221B Baker Street")
        )

        #expect(viewModel.canShowMap == false)
    }

    @Test func testCanShowMap_showMapEnabled_withAddress_shouldBeTrue() {

        settings.toggleShowMap.onNext(true)

        let viewModel = mock(
            event: .make(location: "221B Baker Street")
        )

        #expect(viewModel.canShowMap == true)
    }

    @Test func testCanShowMap_showMapEnabled_withLinkLocation_shouldBeFalse() {

        settings.toggleShowMap.onNext(true)

        let viewModel = mock(
            event: .make(location: "https://example.com")
        )

        #expect(viewModel.canShowMap == false)
    }

    @Test func testCanShowMap_showMapEnabled_withBlacklistedItem_shouldBeFalse() {

        settings.toggleShowMap.onNext(true)
        localStorage.showMapBlacklistItems = ["Conference Room"]

        let viewModel = mock(
            event: .make(location: "Conference Room 2")
        )

        #expect(viewModel.canShowMap == false)
    }

    @Test func testCanShowMap_showMapEnabled_withMatchingBlacklistRegex_shouldBeFalse() {

        settings.toggleShowMap.onNext(true)
        localStorage.showMapBlacklistRegex = "\\d{5}"

        let viewModel = mock(
            event: .make(location: "12345 Main Street")
        )

        #expect(viewModel.canShowMap == false)
    }

    @Test func testCanShowMap_showMapEnabled_withAnchoredBlacklistRegex_shouldNotMatchSubstring() {

        settings.toggleShowMap.onNext(true)
        localStorage.showMapBlacklistRegex = "^\\d{5}$"

        let viewModel = mock(
            event: .make(location: "12345 Main Street")
        )

        #expect(viewModel.canShowMap == true)
    }

    @Test func testCanShowMap_showMapEnabled_withAnchoredBlacklistRegex_shouldMatchWholeLocation() {

        settings.toggleShowMap.onNext(true)
        localStorage.showMapBlacklistRegex = "^\\d{5}$"

        let viewModel = mock(
            event: .make(location: "12345")
        )

        #expect(viewModel.canShowMap == false)
    }

    @Test func testDetails_withUrl_isNotBirthday_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.url == "https://someurl.com")
    }

    @Test func testDetails_withUrl_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        #expect(viewModel.url == "")
    }

    @Test func testDuration_isAllDay_isSingleDay_shouldShowOnlyDate() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            )
        )

        #expect(viewModel.duration == "Jan 1, 2021")
    }

    @Test func testDuration_isAllDay_isMultiDay_shouldShowDateRange() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2),
                isAllDay: true
            )
        )

        #expect(viewModel.duration == "Jan 1 - 2, 2021")
    }

    @Test func testDuration_isReminder_shouldShowOnlyStart() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                type: .reminder(completed: false)
            )
        )

        #expect(viewModel.duration == "Jan 1, 2021 at 10:00 AM")
    }

    @Test func testDuration_isMultiDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2, hour: 20)
            )
        )

        #expect(viewModel.duration == "Jan 1, 2021 at 10:00 AM - Jan 2, 2021 at 8:00 PM")
    }

    @Test func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        #expect(viewModel.duration == "Jan 1, 2021, 3:00 - 4:00 PM")
    }

    @Test func testDuration_endsMidnight() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2)
            )
        )

        #expect(viewModel.duration == "Jan 1, 2021, 10:00 - 12:00 AM")
    }

    @Test func testParticipants_shouldReturnCorrectOrder() {

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

        #expect(viewModel.participants.map(\.name) == ["organizer", "me", "a", "b", "c"])
    }

    @Test func testSkip_withSouceList_shouldNotShowSkip() {

        let viewModel = mock(
            event: .make(type: .event(.unknown)),
            source: .calendar
        )

        #expect(viewModel.showSkip == false)
    }

    @Test func testSkip_withSouceMenubar_shouldShowSkip() {

        let viewModel = mock(
            event: .make(type: .event(.unknown)),
            source: .menubar
        )

        #expect(viewModel.showSkip)
    }

    @Test func testSkip_withSouceMenubar_isBirthday_shouldNotShowSkip() {

        let viewModel = mock(
            event: .make(type: .birthday),
            source: .menubar
        )

        #expect(viewModel.showSkip == false)
    }

    @Test func testSkip_withSouceMenubar_isReminder_shouldNotShowSkip() {

        let viewModel = mock(
            event: .make(type: .reminder(completed: false)),
            source: .menubar
        )

        #expect(viewModel.showSkip == false)
    }

    @Test func testSkip_shouldTriggerClose() async {

        let event: EventModel = .make(type: .event(.unknown))

        var action: ContextCallbackAction?

        let viewModel = mock(
            event: event,
            source: .menubar
        ) {
            action = $0
        }

        #expect(viewModel.showSkip)

        let expectation = expectation(description: "Close")

        viewModel.close
            .subscribe(onCompleted: expectation.fulfill)
            .disposed(by: disposeBag)

        viewModel.skipTapped.onNext(())

        await fulfillment(of: [expectation])

        #expect(action == .event(event, .skip))
    }

    @Test func testStatusChange_shouldTriggerClose() async {

        let event: EventModel = .make(type: .event(.pending))

        var action: ContextCallbackAction?

        let viewModel = mock(
            event: event,
            source: .menubar
        ) {
            action = $0
        }

        let expectation = expectation(description: "Close")

        viewModel.close
            .subscribe(onCompleted: expectation.fulfill)
            .disposed(by: disposeBag)

        let contextMenu = viewModel.makeContextMenuViewModel() as? EventOptionsViewModel

        #expect(contextMenu != nil)

        contextMenu?.triggerAction(.status(.accept))

        await fulfillment(of: [expectation])

        #expect(action == .event(event, .status(.accept)))
    }

    @Test func testOpenLinkWithSelectedBrowser() async {

        mockBrowsers()

        let viewModel = mock(event: .make(location: "https://example.com", calendar: .make(id: "1")))

        let defaultBrowserExpectation = expectation(description: "Default")
        let selectedBrowserExpectation = expectation(description: "Selected")

        workspace.didOpenURL = { url in
            #expect(url.absoluteString == "https://example.com")
            defaultBrowserExpectation.fulfill()
        }

        workspace.didOpenURLWithApplication = { url, appUrl in
            Issue.record("No default browser selected")
            defaultBrowserExpectation.fulfill()
        }

        viewModel.linkTapped.onNext(())

        await fulfillment(of: [defaultBrowserExpectation])

        #expect(localStorage.defaultBrowserPerCalendar == [:])

        viewModel.browserPickerViewModel.selectedIndexObserver.onNext(2)

        let browser2Url = mockAppUrl("Browser 2").absoluteString

        #expect(localStorage.defaultBrowserPerCalendar == ["1": browser2Url])

        workspace.didOpenURLWithApplication = { url, appUrl in
            #expect(url.absoluteString == "https://example.com")
            #expect(appUrl?.absoluteString == browser2Url)
            selectedBrowserExpectation.fulfill()
        }

        viewModel.linkTapped.onNext(())

        await fulfillment(of: [selectedBrowserExpectation])
    }

    func mockBrowsers() {
        workspace.m_urlForApplicationToOpenURL = mockAppUrl("Default")
        workspace.m_urlForApplicationToOpenContentType = mockAppUrl("Default")

        workspace.m_urlsForApplicationsToOpenURL = [mockAppUrl("Browser 2"), mockAppUrl("Browser 1"), mockAppUrl("Default"), mockAppUrl("Browser 3")]
        workspace.m_urlsForApplicationsToOpenContentType = [mockAppUrl("Browser 2"), mockAppUrl("Browser 1"), mockAppUrl("Default"), mockAppUrl("Browser 3"), mockAppUrl("Not a real browser 4")]
    }

    func mock(event: EventModel, source: EventDetailsSource = .calendar, callback: @escaping (ContextCallbackAction?) -> Void = { _ in }) -> EventDetailsViewModel {

        EventDetailsViewModel(
            source: source,
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            localStorage: localStorage,
            settings: settings,
            isShowingObserver: .dummy(),
            callback: .init { callback($0.element) },
            scheduler: scheduler
        )
    }
}
