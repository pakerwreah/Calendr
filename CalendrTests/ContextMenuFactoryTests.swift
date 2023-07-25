//
//  ContextMenuFactoryTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import XCTest
import RxSwift
@testable import Calendr

class ContextMenuFactoryTests: XCTestCase {

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()

    func testFactory_isEvent_withInvitationStatus_shouldMakeViewModel() throws {

        for canOpen in [true, false] {
            for status in [.accepted, .maybe, .pending, .declined] as [EventStatus] {
                let viewModel = try XCTUnwrap(make(event: .make(type: .event(status)), canOpen: canOpen))
                XCTAssert(viewModel is EventOptionsViewModel)
            }
        }
    }

    func testFactory_isEvent_withoutInvitationStatus_canOpenTrue_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .event(.unknown)), canOpen: true))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isEvent_withoutInvitationStatus_canOpenFalse_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .event(.unknown)), canOpen: false))
    }

    func testFactory_isReminder_shouldMakeViewModel() throws {

        for canOpen in [true, false] {
            let viewModel = try XCTUnwrap(make(event: .make(type: .reminder), canOpen: canOpen))
            XCTAssert(viewModel is ReminderOptionsViewModel)
        }
    }

    func testFactory_isBirthday_canOpenTrue_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .birthday), canOpen: true))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isBirthday_canOpenFalse_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .birthday), canOpen: false))
    }

    func make(event: EventModel, canOpen: Bool = true) -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            canOpen: canOpen
        )
    }
}
