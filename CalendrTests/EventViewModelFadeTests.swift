//
//  EventViewModelFadeTests.swift
//  CalendrTests
//
//  Created by Paker on 30/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class EventViewModelFadeTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()

    let workspaceProvider = MockWorkspaceProvider()

    let userDefaults = UserDefaults(suiteName: className())!

    let notificationCenter = NotificationCenter()

    lazy var settings = SettingsViewModel(
        dateProvider: dateProvider,
        userDefaults: userDefaults,
        notificationCenter: notificationCenter
    )

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testFade_isAllDay_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12),
            isAllDay: true
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isMultiDay_doesNotEndToday_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isMultiDay_endsToday_isInProgress_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 11)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isMultiDay_endsToday_isPast_showPastEventsDisabled_shouldNotFade() {

        settings.togglePastEvents.onNext(false)

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isMultiDay_endsToday_isPast_showPastEventsEnabled_shouldFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, true)
    }

    func testFade_isNotToday_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isToday_isFuture_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isToday_isInProgress_shouldNotFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 11)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isToday_isPast_showPastEventsDisabled_shouldNotFade() {

        settings.togglePastEvents.onNext(false)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, false)
    }

    func testFade_isToday_isPast_showPastEventsEnabled_shouldFade() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 12)
        )

        var isFaded: Bool?

        viewModel.isFaded
            .bind { isFaded = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isFaded, true)
    }

    func mock(
        start: Date,
        end: Date,
        isAllDay: Bool = false
    ) -> EventViewModel {

        EventViewModel(
            event: .make(start: start, end: end, isAllDay: isAllDay),
            dateProvider: dateProvider,
            workspaceProvider: workspaceProvider,
            settings: settings
        )
    }
}
