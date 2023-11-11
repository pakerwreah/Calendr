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

    func testOptions_fromList() {

        let viewModel = mock(event: .make(type: .reminder), source: .list)

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

    func testOptions_fromMenuBar() {

        let viewModel = mock(event: .make(type: .reminder), source: .menubar)

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

    func testOptions_fromDetails() {

        let viewModel = mock(event: .make(type: .reminder), source: .details)

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

    func testOptions_withOpenTriggered() {
        let openExpectation = expectation(description: "Open")

        let viewModel = mock(event: .make(id: "12345", type: .reminder), source: .list)

        workspace.didOpen = { url in
            XCTAssertEqual(url.absoluteString, "x-apple-reminderkit://remcdreminder/12345")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        waitForExpectations(timeout: 1)
    }

    func testReminder_rescheduleBy1Hour() {

        let viewModel = mock(event: .make(type: .reminder))

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        var date: Date?
        var callback: ReminderAction?

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(hour: 1))

        viewModel.triggerAction(action)

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 1, hour: 13))
        XCTAssertEqual(callback, action)
    }

    func testReminder_rescheduleTomorrow() {

        let viewModel = mock(event: .make(type: .reminder))

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        var date: Date?
        var callback: ReminderAction?

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .remind(.init(day: 1))

        viewModel.triggerAction(action)

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 2, hour: 12))
        XCTAssertEqual(callback, action)
    }

    func testReminder_markCompleted() {

        let viewModel = mock(event: .make(type: .reminder))

        var complete = false
        var callback: ReminderAction?

        calendarService.spyCompleteObservable
            .bind { complete = true }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = $0 }
            .disposed(by: disposeBag)

        let action: ReminderAction = .complete(.clear)

        viewModel.triggerAction(action)

        XCTAssert(complete)
        XCTAssertEqual(callback, action)
    }

    func mock(event: EventModel, source: ContextMenuSource = .details) -> some ContextMenuViewModel<ReminderAction> {

        ReminderOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source
        )
    }
}
