//
//  EventViewModelHideTests.swift
//  CalendrTests
//
//  Created by Paker on 30/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class EventViewModelHideTests: XCTestCase {

    let disposeBag = DisposeBag()

    let userDefaults = UserDefaults(suiteName: className())!

    lazy var settings = SettingsViewModel(userDefaults: userDefaults)

    private let dateProvider = MockDateProvider()

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testHide_isAllDay_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12),
            isAllDay: true
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isMultiDay_doesNotEndToday_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isMultiDay_endsToday_isInProgress_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 11)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isMultiDay_endsToday_isPast_showPastEventsDisabled_shouldHide() {

        settings.toggleShowPastEvents.onNext(false)

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, true)
    }

    func testHide_isMultiDay_endsToday_isPast_showPastEventsEnabled_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isNotToday_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isToday_isFuture_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isToday_isInProgress_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 11)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isToday_isPast_showPastEventsEnabled_shouldNotHide() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, false)
    }

    func testHide_isToday_isPast_showPastEventsDisabled_shouldHide() {

        settings.toggleShowPastEvents.onNext(false)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isHidden: Bool?

        viewModel.isHidden
            .bind { isHidden = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isHidden, true)
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
