//
//  ReminderOptionsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import XCTest
import RxSwift
@testable import Calendr

class ReminderOptionsViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()

    func testOptions_fromList() throws {

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false)), source: .list))

        XCTAssertEqual(viewModel.items, [
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

    func testOptions_fromMenuBar() throws {

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false)), source: .menubar))

        XCTAssertEqual(viewModel.items, [
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

    func testOptions_fromDetails() throws {

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false)), source: .details))

        XCTAssertEqual(viewModel.items, [
            .action(.complete(.clear)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
    }

    func testOptions_isCompleted_fromDetails() {

        XCTAssertNil(mock(event: .make(type: .reminder(completed: true)), source: .details))
    }

    func testOptions_isCompleted_fromMenuBar() throws {

        XCTAssertNil(mock(event: .make(type: .reminder(completed: true)), source: .menubar))
    }

    func testOptions_isCompleted_fromList() throws {

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: true)), source: .list))

        XCTAssertEqual(viewModel.items, [.action(.open)])
    }

    func testOptions_withOpenTriggered() throws {
        let openExpectation = expectation(description: "Open")

        let viewModel = try XCTUnwrap(mock(event: .make(id: "12345", type: .reminder(completed: false)), source: .list))

        workspace.didOpenEvent = { event in
            XCTAssertEqual(event.id, "12345")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func testReminder_rescheduleBy1Hour() throws {

        var date: Date?
        var callback: ReminderAction?

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false))) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(hour: 1))

        viewModel.triggerAction(action)

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 1, hour: 13))
        XCTAssertEqual(callback, action)
    }

    func testReminder_rescheduleTomorrow() throws {

        var date: Date?
        var callback: ReminderAction?

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false))) {
            callback = $0
        })

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        calendarService.spyRescheduleReminderObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 2, hour: 12))
        XCTAssertEqual(callback, action)
    }

    func testReminder_markCompleted() throws {

        var complete = false
        var callback: ReminderAction?

        let viewModel = try XCTUnwrap(mock(event: .make(type: .reminder(completed: false))) {
            callback = $0
        })

        calendarService.spyCompleteReminderObservable
            .bind { complete = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .complete(.clear)

        viewModel.triggerAction(action)

        XCTAssert(complete)
        XCTAssertEqual(callback, action)
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
