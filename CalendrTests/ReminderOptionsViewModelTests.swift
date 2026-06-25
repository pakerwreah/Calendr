//
//  ReminderOptionsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class ReminderOptionsViewModelTests {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()

    @Test func testOptions_fromList() throws {

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: false)), source: .calendar))

        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.complete(.clear)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
    }

    @Test func testOptions_fromMenuBar() throws {

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: false)), source: .menubar))

        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.complete(.clear)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
    }

    @Test func testOptions_fromDetails() throws {

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: false)), source: .details))

        #expect(viewModel.items == [
            .action(.complete(.clear)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
    }

    @Test func testOptions_isTomorrow_shouldHideTomorrowOption() throws {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = try #require(mock(event: .make(
            start: .make(year: 2021, month: 1, day: 2, hour: 10),
            type: .reminder(completed: false),
        )))

        #expect(viewModel.items == [
            .action(.complete(.clear)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1)))
        ])
    }

    @Test func testOptions_isCompleted_fromDetails() {

        #expect(mock(event: .make(type: .reminder(completed: true)), source: .details) == nil)
    }

    @Test func testOptions_isCompleted_fromMenuBar() throws {

        #expect(mock(event: .make(type: .reminder(completed: true)), source: .menubar) == nil)
    }

    @Test func testOptions_isCompleted_fromList() throws {

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: true)), source: .calendar))

        #expect(viewModel.items == [.action(.open)])
    }

    @Test func testOptions_withOpenTriggered() async throws {
        let openExpectation = expectation(description: "Open")

        let viewModel = try #require(mock(event: .make(id: "12345", type: .reminder(completed: false)), source: .calendar))

        workspace.didOpenEvent = { event in
            #expect(event.id == "12345")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)

        await fulfillment(of: [openExpectation])
    }

    @Test func testReminder_rescheduleBy1Hour() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: false))) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(hour: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 1, hour: 13))
        #expect(args?.isAllDay == false)
        #expect(callback == action)
    }

    @Test func testReminder_rescheduleBy1Hour_allDay() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(isAllDay: true, type: .reminder(completed: false))) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(hour: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 1, hour: 13))
        #expect(args?.isAllDay == false)
        #expect(callback == action)
    }

    @Test func testReminder_rescheduleTomorrow() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            type: .reminder(completed: false))
        ) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 2, hour: 10))
        #expect(args?.isAllDay == false)
        #expect(callback == action)
    }

    @Test func testReminder_rescheduleTomorrow_allDay() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(
            start: .make(year: 2021, month: 1, day: 1, at: .start),
            isAllDay: true,
            type: .reminder(completed: false))
        ) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 2, at: .start))
        #expect(args?.isAllDay == true)
        #expect(callback == action)
    }

    @Test func testReminder_rescheduleTomorrow_fromYesterday() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(
            start: .make(year: 2020, month: 12, day: 31, hour: 10),
            type: .reminder(completed: false))
        ) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 2, hour: 10))
        #expect(args?.isAllDay == false)
        #expect(callback == action)
    }

    @Test func testReminder_rescheduleTomorrow_fromFuture() throws {

        var args: RescheduleReminderArgs?
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(
            start: .make(year: 2021, month: 1, day: 3, hour: 10),
            type: .reminder(completed: false))
        ) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { args = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        #expect(args?.date == .make(year: 2021, month: 1, day: 2, hour: 10))
        #expect(args?.isAllDay == false)
        #expect(callback == action)
    }

    @Test func testReminder_markCompleted() throws {

        var complete = false
        var callback: ReminderAction?

        let viewModel = try #require(mock(event: .make(type: .reminder(completed: false))) {
            callback = $0
        })

        calendarService.spyCompleteReminderObservable
            .bind { complete = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .complete(.clear)

        viewModel.triggerAction(action)

        #expect(complete)
        #expect(callback == action)
    }

    func mock(
        event: EventModel,
        source: ContextMenuSource = .details,
        callback: @escaping (ReminderAction?) -> Void = { _ in }
    ) -> (some ContextMenuViewModel<ReminderAction>)? {

        ReminderOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source,
            callback: .init { callback($0.element) }
        )
    }
}
