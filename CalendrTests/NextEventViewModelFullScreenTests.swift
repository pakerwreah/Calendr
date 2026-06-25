//
//  NextEventViewModelFullScreenTests.swift
//  CalendrTests
//
//  Created by Paker on 01/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class NextEventViewModelFullScreenTests {

    let disposeBag = DisposeBag()

    let calendarsSubject = BehaviorSubject<[String]>(value: [])

    let localStorage = MockLocalStorageProvider()
    let settings = MockNextEventSettings()
    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let screenProvider = MockScreenProvider()
    let scheduler = HistoricalScheduler()
    let soundPlayer = MockSoundProvider()

    func makeViewModel(type: NextEventType) -> NextEventViewModel {
        .init(
            type: type,
            localStorage: localStorage,
            settings: settings,
            nextEventCalendars: calendarsSubject,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetailsModal: .init(value: false),
            scheduler: scheduler,
            soundPlayer: soundPlayer
        )
    }

    var now: Date {
        dateProvider.now
    }

    init() {

        localStorage.reset()

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    @Test func testNextEvent_isInProgress_withFullScreenDisabled_shouldNotPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(false)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen == nil)
    }

    @Test func testNextEvent_isInProgress_withFullScreenToggledOn_shouldPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(false)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen == nil)

        settings.toggleFullScreenEvent.onNext(true)

        #expect(fullScreen != nil)
    }

    @Test func testNextEvent_isNotInProgress_shouldNotPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 10, end: now - 5)
        ])

        #expect(fullScreen == nil)
    }

    @Test func testNextEvent_isInProgress_shouldPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen != nil)
    }

    // local id is not guaranteed to be stable
    @Test func testNextEvent_isInProgress_eventIdChanged_shouldNotReplayFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(id: "1", start: now, end: now + 1)
        ])

        #expect(fullScreen != nil)

        let lastValue = fullScreen

        calendarService.changeEvents([
            .make(id: "2", start: now, end: now + 1)
        ])

        #expect(fullScreen === lastValue)
    }

    // we don't care if someone accept / decline the event
    @Test func testNextEvent_isInProgress_participantsChanged_shouldNotReplayFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        let participants = [Participant.make(name: "John", status: .accepted)]

        calendarService.changeEvents([
            .make(start: now, end: now + 1, participants: participants)
        ])

        #expect(fullScreen != nil)

        let lastValue = fullScreen

        calendarService.changeEvents([
            .make(start: now, end: now + 1, participants: [
                .make(name: "John", status: .declined)
            ])
        ])

        #expect(fullScreen === lastValue)
    }

    // time doesn't matter, we only care if the meeting is in progress or not
    @Test func testNextEvent_isInProgress_timeChanged_shouldNotReplayFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        #expect(fullScreen != nil)

        let lastValue = fullScreen

        calendarService.changeEvents([
            .make(start: now, end: now + 2)
        ])

        #expect(fullScreen === lastValue)
    }

    @Test func testNextEvent_eventRescheduled_shouldPublishNilFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        #expect(fullScreen != nil)

        calendarService.changeEvents([
            .make(start: now + 1, end: now + 2)
        ])

        #expect(fullScreen == nil)
    }

    @Test func testNextEvent_eventEnded_shouldPublishNilFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        #expect(fullScreen != nil)

        dateProvider.add(1, .second)
        scheduler.advance(1, .second)

        #expect(fullScreen == nil)
    }

    @Test func testNextEvent_isInProgress_externalIdChanged_shouldPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(externalId: "1", start: now, end: now + 1, title: "Event 1")
        ])

        #expect(fullScreen?.title == "Event 1")

        calendarService.changeEvents([
            .make(externalId: "2", start: now, end: now + 1, title: "Event 2")
        ])

        #expect(fullScreen?.title == "Event 2")
    }

    @Test func testNextEvent_isInProgress_withScreenLocked_shouldNotPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)
        screenProvider.isLockedObserver.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen == nil)
    }

    @Test func testNextEvent_isInProgress_withScreenUnlocked_shouldPublishFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)
        screenProvider.isLockedObserver.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen == nil)

        screenProvider.isLockedObserver.onNext(false)

        #expect(fullScreen != nil)
    }

    @Test func testNextEvent_isInProgress_withScreenUnlocked_shouldPublishLatestFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)
        screenProvider.isLockedObserver.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(externalId: "1", start: now - 1, end: now + 1, title: "Event 1")
        ])

        #expect(fullScreen == nil)

        calendarService.changeEvents([
            .make(externalId: "2", start: now - 1, end: now + 1, title: "Event 2")
        ])

        #expect(fullScreen == nil)

        screenProvider.isLockedObserver.onNext(false)

        #expect(fullScreen?.title == "Event 2")
    }

    @Test func testNextEvent_isInProgress_withScreenUnlockedThenLocked_shouldNotPublishNilFullScreenViewModel() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1)
        ])

        #expect(fullScreen != nil)

        screenProvider.isLockedObserver.onNext(true)

        #expect(fullScreen != nil)
    }

    @Test func testNextEvent_withFullScreenViewModel_onSkip_shouldSkipGroupedEvents() {

        settings.toggleFullScreenEvent.onNext(true)

        let viewModel = makeViewModel(type: .event)

        var fullScreen: EventFullScreenViewModel?

        viewModel.fullScreenViewModel
            .bind { fullScreen = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(id: "1", externalId: "1", start: now, end: now + 1, title: "Event 1"),
            .make(id: "2", externalId: "2", start: now, end: now + 2, title: "Event 2"),
            .make(id: "3", externalId: "3", start: now, end: now + 3, title: "Event 3")
        ])

        let expectedTitle = "3 events"
        #expect(fullScreen?.title == expectedTitle)
        #expect(viewModel.title.lastValue() == expectedTitle)
        #expect(viewModel.hasEvent.lastValue() == true)

        fullScreen?.onAppear()
        scheduler.advance(.seconds(2))

        fullScreen?.skip()
        scheduler.advance(.milliseconds(1))

        #expect(fullScreen == nil)
        #expect(viewModel.title.lastValue() == nil)
        #expect(viewModel.hasEvent.lastValue() == false)
    }
}
