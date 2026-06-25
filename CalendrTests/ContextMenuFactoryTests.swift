//
//  ContextMenuFactoryTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class ContextMenuFactoryTests {

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()

    @Test func testFactory_isEvent_withInvitationStatus_fromAnySource_shouldMakeViewModel() throws {

        for source: ContextMenuSource in [.calendar, .menubar, .details] {
            for status in [.accepted, .maybe, .pending, .declined] as [EventStatus] {
                let viewModel = try #require(make(event: .make(type: .event(status)), source: source))
                #expect(viewModel is EventOptionsViewModel)
            }
        }
    }

    @Test func testFactory_isEvent_withoutInvitationStatus_fromList_shouldMakeViewModel() throws {

        let viewModel = try #require(make(event: .make(type: .event(.unknown)), source: .calendar))
        #expect(viewModel is EventOptionsViewModel)
    }

    @Test func testFactory_isEvent_withoutInvitationStatus_fromMenuBar_shouldMakeViewModel() throws {

        let viewModel = try #require(make(event: .make(type: .event(.unknown)), source: .menubar))
        #expect(viewModel is EventOptionsViewModel)
    }

    @Test func testFactory_isEvent_withoutInvitationStatus_fromDetails_shouldNotMakeViewModel() {

        #expect(make(event: .make(type: .event(.unknown)), source: .details) == nil)
    }

    @Test func testFactory_isReminder_notCompleted_fromAnySource_shouldMakeViewModel() throws {

        for source: ContextMenuSource in [.calendar, .menubar, .details] {
            let viewModel = try #require(make(event: .make(type: .reminder(completed: false)), source: source))
            #expect(viewModel is ReminderOptionsViewModel)
        }
    }

    @Test func testFactory_isReminder_isCompleted_fromList_shouldMakeViewModel() throws {

        let viewModel = try #require(make(event: .make(type: .reminder(completed: true)), source: .calendar))
        #expect(viewModel is ReminderOptionsViewModel)
    }

    @Test func testFactory_isReminder_isCompleted_fromMenuBar_shouldNotMakeViewModel() throws {

        #expect(make(event: .make(type: .reminder(completed: true)), source: .menubar) == nil)
    }

    @Test func testFactory_isReminder_isCompleted_fromDetails_shouldNotMakeViewModel() throws {

        #expect(make(event: .make(type: .reminder(completed: true)), source: .details) == nil)
    }

    @Test func testFactory_isBirthday_fromList_shouldMakeViewModel() throws {

        let viewModel = try #require(make(event: .make(type: .birthday), source: .calendar))
        #expect(viewModel is EventOptionsViewModel)
    }

    @Test func testFactory_isBirthday_fromMenuBar_shouldMakeViewModel() throws {

        let viewModel = try #require(make(event: .make(type: .birthday), source: .menubar))
        #expect(viewModel is EventOptionsViewModel)
    }

    @Test func testFactory_isBirthday_fromDetails_shouldNotMakeViewModel() {

        #expect(make(event: .make(type: .birthday), source: .details) == nil)
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
