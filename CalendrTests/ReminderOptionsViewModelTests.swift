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

    func testOptions() {

        let viewModel = mock(event: .make(type: .reminder))

        XCTAssertEqual(viewModel.items, [
            .action(.complete),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
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

        viewModel.triggerAction(.complete)

        XCTAssert(complete)
        XCTAssert(callback)
    }

    func mock(event: EventModel) -> ReminderOptionsViewModel {

        ReminderOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService
        )
    }
}
