//
//  EventOptionsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import XCTest
import RxSwift
@testable import Calendr

class EventOptionsViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()

    func testOptions_withPendingInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .details)
        XCTAssertEqual(viewModel.items, [
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_withAcceptedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.accepted)), source: .details)
        XCTAssertEqual(viewModel.items, [
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_withMaybeInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.maybe)), source: .details)
        XCTAssertEqual(viewModel.items, [
            .action(.status(.accept)),
            .action(.status(.decline))
        ])
    }

    func testOptions_withDeclinedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.declined)), source: .details)
        XCTAssertEqual(viewModel.items, [
            .action(.status(.accept)),
            .action(.status(.maybe))
        ])
    }

    func testStatusChanged_shouldChangeStatus() {

        var status: EventStatus?
        var callback: EventAction?

        let viewModel = mock(event: .make(type: .event(.pending)), source: .details) {
            callback = $0
        }

        calendarService.spyChangeEventStatusObservable
            .bind { status = $0 }
            .disposed(by: disposeBag)

        let action: EventAction = .status(.accept)

        viewModel.triggerAction(action)

        XCTAssertEqual(status, .accepted)
        XCTAssertEqual(callback, action)
    }

    func testOptions_fromList_withUnknownInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.unknown)), source: .list)
        XCTAssertEqual(viewModel.items, [.action(.open)])
    }

    func testOptions_fromList_withUnknownInvitationStatus_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.unknown)), source: .list)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false))
        ])
    }

    func testOptions_fromList() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .list)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_fromList_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.pending)), source: .list)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_fromMenuBar_withUnknownInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.unknown)), source: .menubar)
        XCTAssertEqual(viewModel.items, [.action(.open), .separator, .action(.skip)])
    }

    func testOptions_fromMenuBar_withUnknownInvitationStatus_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.unknown)), source: .menubar)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.skip)
        ])
    }

    func testOptions_fromMenuBar() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .menubar)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.skip),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_fromMenuBar_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.pending)), source: .menubar)
        XCTAssertEqual(viewModel.items, [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.skip),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    func testOptions_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")

        let viewModel = mock(event: .make(id: "12345", type: .event(.pending)), source: .list)

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func testOptions_withRecurrenceRules_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+1")!

        let viewModel = mock(
            event: .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                type: .event(.pending),
                hasRecurrenceRules: true
            ),
            source: .list
        )

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T000000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func testOptions_withRecurrenceRules_isAllDay_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")
        let timeZone = TimeZone(abbreviation: "UTC+3")!

        let viewModel = mock(
            event: .make(
                id: "12345",
                start: .make(year: 2021, month: 1, day: 1),
                isAllDay: true,
                type: .event(.pending),
                hasRecurrenceRules: true
            ),
            source: .list
        )

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T030000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func testEventLinkAction_isMeeting() {
        XCTAssertEqual(EventAction.link(.zoomLink, isInProgress: false).title, Strings.EventAction.join)
        
        XCTAssertEqual(EventAction.link(.zoomLink, isInProgress: false).icon, Icons.Event.video)
        
        XCTAssertEqual(
            EventAction.link(.zoomLink, isInProgress: true).icon?.tiffRepresentation,
            Icons.Event.video_fill.with(color: .controlAccentColor).tiffRepresentation
        )
    }

    func testEventLinkAction_isGenericLink() {
        XCTAssertEqual(EventAction.link(.genericLink, isInProgress: false).title, "google.com")
        
        XCTAssertEqual(EventAction.link(.genericLink, isInProgress: false).icon, Icons.Event.link)
        
        XCTAssertEqual(
            EventAction.link(.genericLink, isInProgress: true).icon?.tiffRepresentation,
            Icons.Event.link.with(color: .controlAccentColor).tiffRepresentation
        )
    }

    func mock(
        event: EventModel,
        source: ContextMenuSource,
        callback: @escaping (EventAction?) -> Void = { _ in }
    ) -> some ContextMenuViewModel<EventAction> {

        EventOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source,
            callback: .init { callback($0.element) }
        )!
    }
}

private extension EventLink {

    static let zoomLink: Self = .init(url: URL(string: "https://zoom.us/j/9999999999")!, isMeeting: true)
    static let genericLink: Self = .init(url: URL(string: "https://google.com/something")!, isMeeting: false)
}
