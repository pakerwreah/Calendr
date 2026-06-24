//
//  MainViewModelDateNavigationTests.swift
//  CalendrTests
//
//  Created by Paker on 20/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class MainViewModelDateNavigationTests {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let settings = MockCalendarSettings()
    let autoUpdater = MockAutoUpdater()
    let isAppActive = BehaviorSubject(value: true)
    let notificationCenter = NotificationCenter()
    let workspace = MockWorkspaceServiceProvider()

    var viewModel: MainViewModel!
    var values = [String]()

    init() {
        dateProvider.now = .make(year: 2021, month: 1, day: 1)

        viewModel = MainViewModel(
            dateProvider: dateProvider,
            settings: settings,
            autoUpdater: autoUpdater,
            isAppActive: isAppActive.asObservable(),
            notificationCenter: notificationCenter,
            workspace: workspace
        )

        values = []

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate

        viewModel.selectedDate
            .map(formatter.string(from:))
            .bind { [weak self] in
                self?.values.append($0)
            }
            .disposed(by: disposeBag)
    }

    @Test func testInitial() {
        dateProvider.now = .make(year: 2025, month: 1, day: 1)
        viewModel.resetObserver.onNext(())

        #expect(values.last == "2025-01-01")
    }

    @Test func testSelect() {
        viewModel.selectDateObserver.onNext(.make(year: 2025, month: 1, day: 1))

        #expect(values.last == "2025-01-01")
    }

    @Test func testReset() {
        viewModel.selectDateObserver.onNext(.make(year: 2025, month: 1, day: 1))
        viewModel.resetObserver.onNext(())

        #expect(values == ["2021-01-01", "2025-01-01", "2021-01-01"])
    }

    @Test func testDistinct() {
        viewModel.navigationObserver.onNext(.arrow(.right))
        dateProvider.now = .make(year: 2021, month: 1, day: 2)
        viewModel.resetObserver.onNext(())
        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 2))
        viewModel.resetObserver.onNext(())

        #expect(values == ["2021-01-01", "2021-01-02"])
    }

    @Test func testPrevDay() {
        viewModel.navigationObserver.onNext(.arrow(.left))

        #expect(values.last == "2020-12-31")
    }

    @Test func testNextDay() {
        viewModel.navigationObserver.onNext(.arrow(.right))

        #expect(values.last == "2021-01-02")
    }

    @Test func testPrevWeek() {
        viewModel.navigationObserver.onNext(.arrow(.up))

        #expect(values.last == "2020-12-25")
    }

    @Test func testNextWeek() {
        viewModel.navigationObserver.onNext(.arrow(.down))

        #expect(values.last == "2021-01-08")
    }

    @Test func testPrevMonth() {
        viewModel.prevMonthObserver.onNext(())

        #expect(values.last == "2020-12-01")
    }

    @Test func testNextMonth() {
        viewModel.nextMonthObserver.onNext(())

        #expect(values.last == "2021-02-01")
    }

    @Test func testSequence() {
        let steps: [() -> Void] = [
            { self.viewModel.navigationObserver.onNext(.arrow(.left)) },
            { self.viewModel.navigationObserver.onNext(.arrow(.right)) },
            { self.viewModel.navigationObserver.onNext(.arrow(.up)) },
            { self.viewModel.navigationObserver.onNext(.arrow(.down)) },
            { self.viewModel.prevMonthObserver.onNext(()) },
            { self.viewModel.nextMonthObserver.onNext(()) },
        ]

        steps.forEach { step in
            step()
        }

        #expect(values == [
            "2021-01-01", // initial
            "2020-12-31", // prevDay
            "2021-01-01", // nextDay
            "2020-12-25", // prevWeek
            "2021-01-01", // nextWeek
            "2020-12-01", // prevMonth
            "2021-01-01", // nextMonth
        ])
    }
}
