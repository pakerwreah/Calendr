//
//  EventViewModelProgressTests.swift
//  CalendrTests
//
//  Created by Paker on 30/01/21.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventViewModelProgressTests {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventSettings()
    let localStorage = MockLocalStorageProvider()

    @Test func testProgress_isAllDay_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            isAllDay: true
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        #expect(progress == nil)
    }

    @Test func testProgress_isMultiDay_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 2, hour: 15)
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        #expect(progress == nil)
    }

    @Test func testProgress_isToday_isFuture_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        #expect(progress == nil)
    }

    @Test func testProgress_isToday_isPast_shouldNotCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 16)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        #expect(progress == nil)
    }

    @Test func testProgress_isInProgress_shouldCalculateProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        #expect(progress == 0.4)
    }

    @Test func testProgress_isNotInProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var isInProgress: Bool?

        viewModel.isInProgress
            .bind { isInProgress = $0 }
            .disposed(by: disposeBag)

        #expect(isInProgress == false)
    }

    @Test func testProgress_isInProgress() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var isInProgress: Bool?

        viewModel.isInProgress
            .bind { isInProgress = $0 }
            .disposed(by: disposeBag)

        #expect(isInProgress == true)
    }

    @Test func testProgress_isNotInProgress_shouldShowClearBackground() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var backgroundColor: EventBackground?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        #expect(backgroundColor == .clear)
    }

    @Test func testProgress_isInProgress_shouldShowColoredBackgroundWithAlpha() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15)
        )

        var backgroundColor: EventBackground?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        #expect(backgroundColor == .color(viewModel.color.withAlphaComponent(0.15)))
    }

    @Test func testProgress_isNotInProgress_isPending_shouldShowPendingBackground() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            type: .event(.pending)
        )

        var backgroundColor: EventBackground?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        #expect(backgroundColor == .pending)
    }

    @Test func testProgress_isInProgress_isPending_shouldShowPendingBackground() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            type: .event(.pending)
        )

        var backgroundColor: EventBackground?

        viewModel.backgroundColor
            .bind { backgroundColor = $0 }
            .disposed(by: disposeBag)

        #expect(backgroundColor == .pending)
    }

    @Test func testProgressClock() {

        // 1 second before the event starts
        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 9, minute: 59, second: 59)

        let scheduler = HistoricalScheduler(initialClock: dateProvider.now)

        let viewModel = mock(
            start: .make(year: 2021, month: 1, day: 1, hour: 10),
            end: .make(year: 2021, month: 1, day: 1, hour: 15),
            scheduler: scheduler
        )

        var progress: CGFloat? = -1

        viewModel.progress
            .bind { progress = $0 }
            .disposed(by: disposeBag)

        // event should not be in progress yet
        #expect(progress == nil)

        // now the event has started
        dateProvider.now += 1

        // check that the progress is not computed before 1 second
        scheduler.advance(.milliseconds(500))
        #expect(progress == nil)

        // now the progress should be computed
        scheduler.advance(.milliseconds(500))
        #expect(progress == 0)

        // 20% progress
        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 11)
        scheduler.advance(.seconds(1))
        #expect(progress == 0.2)

        // 100% progress
        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 15)
        scheduler.advance(.seconds(1))
        #expect(progress == 1)

        // event finished
        dateProvider.add(1, .second)
        scheduler.advance(.seconds(1))
        #expect(progress == nil)
    }

    func mock(
        start: Date,
        end: Date,
        isAllDay: Bool = false,
        type: EventType = .event(.accepted),
        scheduler: SchedulerType = MainScheduler.instance
    ) -> EventViewModel {

        EventViewModel(
            source: .calendar,
            event: .make(start: start, end: end, isAllDay: isAllDay, type: type),
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            localStorage: localStorage,
            settings: settings,
            isShowingDetailsModal: .dummy(),
            callback: .dummy(),
            isTodaySelected: true,
            scheduler: scheduler
        )
    }
}
