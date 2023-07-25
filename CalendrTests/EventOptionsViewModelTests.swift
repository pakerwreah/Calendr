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

        let viewModel = mock(event: .make(type: .event(.pending)))
        XCTAssertEqual(viewModel.items, [.action(.accept), .action(.maybe), .action(.decline)])
    }

    func testOptions_withAcceptedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.accepted)))
        XCTAssertEqual(viewModel.items, [.action(.maybe), .action(.decline)])
    }

    func testOptions_withMaybeInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.maybe)))
        XCTAssertEqual(viewModel.items, [.action(.accept), .action(.decline)])
    }

    func testOptions_withDeclinedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.declined)))
        XCTAssertEqual(viewModel.items, [.action(.accept), .action(.maybe)])
    }

    func testStatusChanged_shouldChangeStatus() {

        let viewModel = mock(event: .make(type: .event(.pending)))

        var status: EventStatus?
        var callback = false

        calendarService.spyChangeEventStatusObservable
            .bind { status = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.triggerAction(.accept)

        XCTAssertEqual(status, .accepted)
        XCTAssert(callback)
    }

    func testOptions_fromList_withUnknownInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.unknown)), canOpen: true)
        XCTAssertEqual(viewModel.items, [.action(.open)])
    }

    func testOptions_fromList() {

        let viewModel = mock(event: .make(type: .event(.pending)), canOpen: true)
        XCTAssertEqual(viewModel.items, [.action(.open), .separator, .action(.accept), .action(.maybe), .action(.decline)])
    }

    func testOptions_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")

        let viewModel = mock(event: .make(id: "12345", type: .event(.pending)), canOpen: true)

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
            canOpen: true
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
            canOpen: true
        )

        dateProvider.m_calendar.timeZone = timeZone

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/20210101T030000Z/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func mock(event: EventModel, canOpen: Bool = false) -> EventOptionsViewModel {

        EventOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            canOpen: canOpen
        )!
    }
}
