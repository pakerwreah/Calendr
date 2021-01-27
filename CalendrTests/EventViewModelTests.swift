//
//  EventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 27/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class EventViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    private let dateProvider = MockDateProvider()

    func testBasicInfo() {

        let calendar = CalendarModel(identifier: "", account: "", title: "", color: .black)
        let event: EventModel = .make(start: Date(), end: Date(), title: "Title", isPending: true, calendar: calendar)
        let viewModel = EventViewModel(event: event, dateProvider: dateProvider)

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.color, .black)
        XCTAssertEqual(viewModel.isPending, true)
    }

    func testDuration_isAllDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1),
            end: .make(year: 2021, month: 1, day: 1),
            isAllDay: true
        )

        XCTAssertEqual(viewModel.duration, "")
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 1, hour: 16)
        )

        XCTAssertEqual(viewModel.duration, "15:00 - 16:00")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 2, hour: 0)
        )

        XCTAssertEqual(viewModel.duration, "15:00 - 00:00")
    }

    func testDuration_isMultiDay() {

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 15),
            end: .make(year: 2021, month: 1, day: 2, hour: 0, minute: 1)
        )

        XCTAssertEqual(viewModel.duration, "Start: 2021-01-01 15:00\nEnd:   2021-01-02 00:01")
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

    func testFade_isMultiDay_endsToday_isPast_shouldFade() {

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

    func testFade_isToday_isPast_shouldFade() {

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
            scheduler: scheduler
        )
    }
}

private class MockDateProvider: DateProviding {
    let calendar = Calendar(identifier: .iso8601)
    var now: Date = .make(year: 2021, month: 1, day: 1)
}
