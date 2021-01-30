//
//  EventViewModelProgressTests.swift
//  CalendrTests
//
//  Created by Paker on 30/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class EventViewModelProgressTests: XCTestCase {

    let disposeBag = DisposeBag()

    let userDefaults = UserDefaults(suiteName: className())!

    lazy var settings = SettingsViewModel(userDefaults: userDefaults)

    private let dateProvider = MockDateProvider()

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testProgress_isAllDay_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            isAllDay: true
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        XCTAssertNil(progress)
    }

    func testProgress_isMultiDay_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 15)
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        XCTAssertNil(progress)
    }

    func testProgress_isToday_isFuture_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        XCTAssertNil(progress)
    }

    func testProgress_isToday_isPast_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 16)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        XCTAssertNil(progress)
    }

    func testProgress_isInProgress_shouldCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(progress, 0.4)
    }

    func testProgress_isNotInProgress_shouldHideLine() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var isLineVisible: Bool?

        viewModel.isLineVisible
            .bind { isLineVisible = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isLineVisible, false)
    }

    func testProgress_isInProgress_shouldShowLine() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var isLineVisible: Bool?

        viewModel.isLineVisible
            .bind { isLineVisible = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isLineVisible, true)
    }

    func testProgress_isNotInProgress_shouldShowClearBackground() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var backgroundColor: CGColor?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(backgroundColor, .clear)
    }

    func testProgress_isInProgress_shouldShowColoredBackgroundWithAlpha() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var backgroundColor: CGColor?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(backgroundColor, viewModel.color.copy(alpha: 0.1))
    }

    func testProgressClock() {

        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9, minute: 59, second: 59)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            scheduler: scheduler
        )

        var progress: CGFloat?

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 10)

        scheduler.advanceTo(5)
        XCTAssertNil(progress)

        scheduler.advanceTo(10)
        XCTAssertEqual(progress, 0)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 11)

        scheduler.advanceTo(20)
        XCTAssertEqual(progress, 0.2)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        scheduler.advanceTo(30)
        XCTAssertEqual(progress, 1)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15, second: 1)

        scheduler.advanceTo(40)
        XCTAssertNil(progress)
    }

    func mock(
        start: Date,
        end: Date,
        isAllDay: Bool = false,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> EventViewModel {

        EventViewModel(
            event: .make(start: start, end: end, isAllDay: isAllDay),
            dateProvider: dateProvider,
            settings: settings,
            scheduler: scheduler
        )
    }
}
