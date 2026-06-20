//
//  MainViewModelDateNavigationTests.swift
//  CalendrTests
//
//  Created by Paker on 20/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class MainViewModelDateNavigationTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let settings = MockCalendarSettings()
    let autoUpdater = MockAutoUpdater()
    let isAppActive = BehaviorSubject(value: true)
    let notificationCenter = NotificationCenter()
    let workspace = MockWorkspaceServiceProvider()

    var viewModel: MainViewModel!
    var values = [String]()

    override func setUp() {
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

    func testInitial() {
        dateProvider.now = .make(year: 2025, month: 1, day: 1)
        viewModel.resetObserver.onNext(())

        XCTAssertEqual(values.last, "2025-01-01")
    }

    func testSelect() {
        viewModel.selectDateObserver.onNext(.make(year: 2025, month: 1, day: 1))

        XCTAssertEqual(values.last, "2025-01-01")
    }

    func testReset() {
        viewModel.selectDateObserver.onNext(.make(year: 2025, month: 1, day: 1))
        viewModel.resetObserver.onNext(())

        XCTAssertEqual(values, ["2021-01-01", "2025-01-01", "2021-01-01"])
    }

    func testDistinct() {
        viewModel.navigationObserver.onNext(.arrow(.right))
        dateProvider.now = .make(year: 2021, month: 1, day: 2)
        viewModel.resetObserver.onNext(())
        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 2))
        viewModel.resetObserver.onNext(())

        XCTAssertEqual(values, ["2021-01-01", "2021-01-02"])
    }

    func testPrevDay() {
        viewModel.navigationObserver.onNext(.arrow(.left))

        XCTAssertEqual(values.last, "2020-12-31")
    }

    func testNextDay() {
        viewModel.navigationObserver.onNext(.arrow(.right))

        XCTAssertEqual(values.last, "2021-01-02")
    }

    func testPrevWeek() {
        viewModel.navigationObserver.onNext(.arrow(.up))

        XCTAssertEqual(values.last, "2020-12-25")
    }

    func testNextWeek() {
        viewModel.navigationObserver.onNext(.arrow(.down))

        XCTAssertEqual(values.last, "2021-01-08")
    }

    func testPrevMonth() {
        viewModel.prevMonthObserver.onNext(())

        XCTAssertEqual(values.last, "2020-12-01")
    }

    func testNextMonth() {
        viewModel.nextMonthObserver.onNext(())

        XCTAssertEqual(values.last, "2021-02-01")
    }

    func testSequence() {
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

        XCTAssertEqual(values, [
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
