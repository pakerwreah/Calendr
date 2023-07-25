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

    func testOptions_canOpenTrue() {

        let viewModel = mock(event: .make(type: .reminder), canOpen: true)

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

    func testOptions_canOpenFalse() {

        let viewModel = mock(event: .make(type: .reminder), canOpen: false)

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

        let viewModel = mock(event: .make(id: "12345", type: .reminder), canOpen: true)

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
        var callback = false

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.triggerAction(.remind(.init(hour: 1)))

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 1, hour: 13))
        XCTAssert(callback)
    }

    func testReminder_rescheduleTomorrow() {

        let viewModel = mock(event: .make(type: .reminder))

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        var date: Date?
        var callback = false

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.triggerAction(.remind(.init(day: 1)))

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 2, hour: 12))
        XCTAssert(callback)
    }

    func testReminder_markCompleted() {

        let viewModel = mock(event: .make(type: .reminder))

        var complete = false
        var callback = false

        calendarService.spyCompleteObservable
            .bind { complete = true }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.triggerAction(.complete(.clear))

        XCTAssert(complete)
        XCTAssert(callback)
    }

    func mock(event: EventModel, canOpen: Bool = false) -> ReminderOptionsViewModel {

        ReminderOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            canOpen: canOpen
        )
    }
}
