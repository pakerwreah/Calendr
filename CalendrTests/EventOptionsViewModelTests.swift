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

    let calendarService = MockCalendarServiceProvider()

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

    func mock(event: EventModel) -> EventOptionsViewModel {

        EventOptionsViewModel(
            event: event,
            calendarService: calendarService
        )
    }
}
