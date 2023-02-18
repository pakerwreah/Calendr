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

    func testFactory_isEvent_withInvitationStatus_shouldMakeViewModel() throws {

        for status in [.accepted, .maybe, .pending, .declined] as [EventStatus] {
            let viewModel = try XCTUnwrap(make(event: .make(type: .event(status))))
            XCTAssert(viewModel is EventOptionsViewModel)
        }
    }

    func testFactory_isEvent_withoutInvitationStatus_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .event(.unknown))))
    }

    func testFactory_isReminder_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .reminder)))
        XCTAssert(viewModel is ReminderOptionsViewModel)
    }

    func testFactory_isBirthday_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .birthday)))
    }

    func make(event: EventModel) -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService
        )
    }
}
