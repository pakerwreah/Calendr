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

    func testFactory_isEvent_withInvitationStatus_fromAnySource_shouldMakeViewModel() throws {

        for source: ContextMenuSource in [.list, .menubar, .details] {
            for status in [.accepted, .maybe, .pending, .declined] as [EventStatus] {
                let viewModel = try XCTUnwrap(make(event: .make(type: .event(status)), source: source))
                XCTAssert(viewModel is EventOptionsViewModel)
            }
        }
    }

    func testFactory_isEvent_withoutInvitationStatus_fromList_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .event(.unknown)), source: .list))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isEvent_withoutInvitationStatus_fromMenuBar_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .event(.unknown)), source: .menubar))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isEvent_withoutInvitationStatus_fromDetails_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .event(.unknown)), source: .details))
    }

    func testFactory_isReminder_notCompleted_fromAnySource_shouldMakeViewModel() throws {

        for source: ContextMenuSource in [.list, .menubar, .details] {
            let viewModel = try XCTUnwrap(make(event: .make(type: .reminder(completed: false)), source: source))
            XCTAssert(viewModel is ReminderOptionsViewModel)
        }
    }

    func testFactory_isReminder_isCompleted_fromList_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .reminder(completed: true)), source: .list))
        XCTAssert(viewModel is ReminderOptionsViewModel)
    }

    func testFactory_isReminder_isCompleted_fromMenuBar_shouldNotMakeViewModel() throws {

        XCTAssertNil(make(event: .make(type: .reminder(completed: true)), source: .menubar))
    }

    func testFactory_isReminder_isCompleted_fromDetails_shouldNotMakeViewModel() throws {

        XCTAssertNil(make(event: .make(type: .reminder(completed: true)), source: .details))
    }

    func testFactory_isBirthday_fromList_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .birthday), source: .list))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isBirthday_fromMenuBar_shouldMakeViewModel() throws {

        let viewModel = try XCTUnwrap(make(event: .make(type: .birthday), source: .menubar))
        XCTAssert(viewModel is EventOptionsViewModel)
    }

    func testFactory_isBirthday_fromDetails_shouldNotMakeViewModel() {

        XCTAssertNil(make(event: .make(type: .birthday), source: .details))
    }

    func make(event: EventModel, source: ContextMenuSource) -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source,
            callback: .dummy()
        )
    }
}
