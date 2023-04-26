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

        let viewModel = mock(event: .make(type: .event(.unknown)), source: .list)
        XCTAssertEqual(viewModel.items, [.action(.open)])
    }

    func testOptions_fromList() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .list)
        XCTAssertEqual(viewModel.items, [.action(.open), .separator, .action(.accept), .action(.maybe), .action(.decline)])
    }

    func testOptions_fromList_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")

        let viewModel = mock(event: .make(id: "12345", type: .event(.pending)), source: .list)

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "ical://ekevent/12345?method=show&options=more")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func mock(event: EventModel, source: ContextMenuSource = .details) -> EventOptionsViewModel {

        EventOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source
        )!
    }
}
