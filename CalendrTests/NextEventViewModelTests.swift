//
//  NextEventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class NextEventViewModelTests {

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

    @Test func testSaveStatusItemPreferredPosition() {

        let viewModel = makeViewModel(type: .event)
        let key = viewModel.preferredPositionKey
        let savedKey = viewModel.savedPreferredPositionKey

        localStorage.set(123, forKey: key)
        #expect(localStorage.integer(forKey: savedKey) == 123)
    }

    @Test func testRestoreStatusItemPreferredPosition() {

        let viewModel = makeViewModel(type: .event)

        let key = viewModel.preferredPositionKey
        let savedKey = viewModel.savedPreferredPositionKey

        #expect(localStorage.integer(forKey: key) == 0)

        localStorage.set(123, forKey: savedKey)
        viewModel.restorePreferredPosition()

        #expect(localStorage.integer(forKey: key) == 123)
    }

    @Test func testRestoreStatusItemPreferredPosition_ignoresMissingSavedPosition() {

        let viewModel = makeViewModel(type: .event)
        let key = viewModel.preferredPositionKey
        let savedKey = viewModel.savedPreferredPositionKey

        #expect(localStorage.integer(forKey: savedKey) == 0)

        localStorage.set(123, forKey: key)
        viewModel.restorePreferredPosition()

        #expect(localStorage.integer(forKey: key) == 123)
    }

    @Test func testNextEvent_noEvent() {

        let viewModel = makeViewModel(type: .event)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 2, end: now - 1)
        ])

        #expect(hasEvent == false)
    }

    @Test func testNextEvent_hasEvent() {

        let viewModel = makeViewModel(type: .event)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        #expect(hasEvent == true)
    }

    @Test func testNextEvent_isNotEnabled_noEvent() {

        let viewModel = makeViewModel(type: .event)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        #expect(hasEvent == true)

        settings.toggleStatusItem.onNext(false)

        #expect(hasEvent == false)
    }

    @Test func testNextEvent_checkRange() {

        let viewModel = makeViewModel(type: .event)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, at: .end)

        let hoursToCheck = 2
        var start = now + TimeInterval(hoursToCheck * 3600)

        settings.eventStatusItemCheckRangeObserver.onNext(hoursToCheck)

        calendarService.changeEvents([
            .make(start: start, end: start + 1)
        ])

        #expect(hasEvent == true)

        start += 1

        calendarService.changeEvents([
            .make(start: start, end: start + 1)
        ])

        #expect(hasEvent == false)
    }

    @Test func testNextEvent_checkRangeZero_shouldCheck30min() {

        let viewModel = makeViewModel(type: .event)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        dateProvider.now = .make(year: 2021, month: 1, day: 1, at: .end)

        let hoursToCheck = 0
        var start = now + 30 * 60

        settings.eventStatusItemCheckRangeObserver.onNext(hoursToCheck)

        calendarService.changeEvents([
            .make(start: start, end: start + 1)
        ])

        #expect(hasEvent == true)

        start += 1

        calendarService.changeEvents([
            .make(start: start, end: start + 1)
        ])

        #expect(hasEvent == false)
    }

    @Test func testNextEventLength() {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event with a text")
        ])

        settings.eventStatusItemLengthObserver.onNext(30)

        #expect(title == "This is an event with a text")

        settings.eventStatusItemLengthObserver.onNext(11)

        // trimmed space (result: 10 chars)
        #expect(title == "This is an.")
    }

    @Test func testNextEventLengthWithNotch() {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event with a text")
        ])

        settings.eventStatusItemLengthObserver.onNext(30)

        #expect(title == "This is an event with a text")

        settings.toggleEventStatusItemDetectNotch.onNext(true)

        #expect(title == "This is an event with a text")

        screenProvider.screenObserver.onNext(MockScreen(hasNotch: true))

        #expect(title == "This i.")

        settings.eventStatusItemNotchLengthObserver.onNext(5)

        // trimmed space (result: 4 chars)
        #expect(title == "This.")

        settings.eventStatusItemNotchLengthObserver.onNext(0)

        #expect(title == "")
    }

    @Test func testNextEventTitleVisibility() {

        let viewModel = makeViewModel(type: .event)

        var isTitleVisible: Bool?

        viewModel.isTitleVisible
            .bind { isTitleVisible = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event")
        ])

        settings.eventStatusItemLengthObserver.onNext(1)

        #expect(isTitleVisible == true)

        settings.eventStatusItemLengthObserver.onNext(0)

        #expect(isTitleVisible == false)
    }

    @Test func testNextEventTitleVisibilityWithNotch() {

        let viewModel = makeViewModel(type: .event)

        var isTitleVisible: Bool?

        viewModel.isTitleVisible
            .bind { isTitleVisible = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event")
        ])

        settings.toggleEventStatusItemDetectNotch.onNext(true)
        screenProvider.screenObserver.onNext(MockScreen(hasNotch: true))

        settings.eventStatusItemNotchLengthObserver.onNext(1)

        #expect(isTitleVisible == true)

        settings.eventStatusItemNotchLengthObserver.onNext(0)

        #expect(isTitleVisible == false)
    }

    @Test func testNextEvent_barStyle() {

        let viewModel = makeViewModel(type: .event)

        var style: EventBarStyle?

        viewModel.barStyle
            .bind { style = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([.make(start: now, type: .event(.accepted))])
        #expect(style == .filled)

        calendarService.changeEvents([.make(start: now, type: .event(.maybe))])
        #expect(style == .bordered)
    }

    @Test func testNextEvent_barColor() {

        let viewModel = makeViewModel(type: .event)

        var color: NSColor?

        viewModel.barColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, calendar: .make(color: .white))
        ])

        #expect(color == .white)
    }

    @Test func testNextEvent_backgroundColor() {

        let viewModel = makeViewModel(type: .event)

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 1, end: now + 2, calendar: .make(color: .white))
        ])

        #expect(color == .clear)
    }

    @Test func testNextEvent_isInProgress_backgroundColor() {

        let viewModel = makeViewModel(type: .event)

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1, calendar: .make(color: .white))
        ])

        #expect(color == .white.withAlphaComponent(0.3))
    }

    @Test func testNextEvent_isPending_backgroundColor() {

        let viewModel = makeViewModel(type: .event)

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 1, end: now + 2, type: .event(.pending), calendar: .make(color: .white))
        ])

        #expect(color == .clear)
    }

    @Test func testNextEvent_isInProgress_isPending_backgroundColor() {

        let viewModel = makeViewModel(type: .event)

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1, type: .event(.pending), calendar: .make(color: .white))
        ])

        #expect(color == .clear)
    }

    @Test func testNextEvent_isAllDay_shouldNotAppear() {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", isAllDay: true),
            .make(start: now + 1, end: now + 2, title: "Event 2", isAllDay: false)
        ])

        #expect(title == "Event 2")
    }

    @Test func testNextEvent_isPending_shouldAppear() {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", type: .event(.pending))
        ])

        #expect(title == "Event 1")
    }

    @Test func testNextEvent_withSameStart_shouldAggregate() {

        let viewModel = makeViewModel(type: .event)

        var title: String?
        var time: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 30, end: now + 10, title: "Event 1", type: .event(.pending)),
            .make(start: now + 30, end: now + 20, title: "Event 2", type: .event(.accepted)),
            .make(start: now + 30, end: now + 30, title: "Event 3", type: .event(.maybe)),
            .make(start: now + 30, end: now + 40, title: "Event 4", type: .event(.declined)),
        ])

        #expect(title == "3 events")
        #expect(time == "in 30s")
    }

    @Test func testNextEvent_withSameStart_isInProgress_endsInLongestEnd() {

        let viewModel = makeViewModel(type: .event)

        var title: String?
        var time: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 10, title: "Event 1", type: .event(.pending)),
            .make(start: now, end: now + 40, title: "Event 2", type: .event(.accepted)),
            .make(start: now, end: now + 60, title: "Event 3", type: .event(.maybe)),
            .make(start: now, end: now + 120, title: "Event 4", type: .event(.declined)),
        ])

        #expect(title == "3 events")
        #expect(time == "1m left")

        dateProvider.now.addTimeInterval(30)
        scheduler.advance(.seconds(1))

        #expect(title == "2 events")
        #expect(time == "30s left")

        dateProvider.now.addTimeInterval(20)
        scheduler.advance(.seconds(1))

        #expect(title == "Event 3")
        #expect(time == "10s left")
    }

    @Test func testNextEvent_startsIn30Seconds() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 30, end: now + 60)
        ])

        #expect(time == "in 30s")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        #expect(time == "in 29s")
    }

    @Test func testNextEvent_startsInLessThan1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 59, end: now + 60)
        ])

        #expect(time == "in 1m")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        #expect(time == "in 1m")

        dateProvider.now.addTimeInterval(28)
        scheduler.advance(.seconds(1))

        #expect(time == "in 30s")
    }

    @Test func testNextEvent_startsIn1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 60, end: now + 70)
        ])

        #expect(time == "in 1m")
    }

    @Test func testNextEvent_startsInMoreThan1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 65, end: now + 70)
        ])

        #expect(time == "in 2m")

        dateProvider.now.addTimeInterval(5)
        scheduler.advance(.seconds(1))

        #expect(time == "in 1m")
    }

    @Test func testNextEvent_startsIn1Hour() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 3600, end: now + 3610)
        ])

        #expect(time == "in 1h")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "in 59m")
    }

    @Test func testNextEvent_startsInMoreThan1Hour() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 6000, end: now + 6010)
        ])

        #expect(time == "in 1h 40m")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "in 1h 39m")
    }

    @Test func testNextEvent_startsInMoreThan24Hours() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 24 * 3600 + 60, end: now + 24 * 3600 + 70)
        ])

        #expect(time == nil)

        settings.eventStatusItemCheckRangeObserver.onNext(25)

        #expect(time == "in 1d")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "in 1d")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "in 23h 59m")
    }

    @Test func testNextEvent_isInProgress_endsIn30Seconds() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 30)
        ])

        #expect(time == "30s left")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        #expect(time == "29s left")
    }

    @Test func testNextEvent_isInProgress_endsInLessThan1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 59)
        ])

        #expect(time == "1m left")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        #expect(time == "1m left")

        dateProvider.now.addTimeInterval(28)
        scheduler.advance(.seconds(1))

        #expect(time == "30s left")
    }

    @Test func testNextEvent_isInProgress_endsIn1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 60)
        ])

        #expect(time == "1m left")
    }

    @Test func testNextEvent_isInProgress_endsInMoreThan1Minute() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 65)
        ])

        #expect(time == "2m left")

        dateProvider.now.addTimeInterval(5)
        scheduler.advance(.seconds(1))

        #expect(time == "1m left")
    }

    @Test func testNextEvent_isInProgress_endsIn1Hour() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 3600)
        ])

        #expect(time == "1h left")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "59m left")
    }

    @Test func testNextEvent_isInProgress_endsInMoreThan1Hour() {

        let viewModel = makeViewModel(type: .event)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 6000)
        ])

        #expect(time == "1h 40m left")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "1h 39m left")
    }

    @Test func testNextEvent_isInProgress_withFartherUpcomingEvent_shouldNotShowUpcoming() {

        let viewModel = makeViewModel(type: .event)

        calendarService.changeEvents([
            .make(id: "1", start: now - 60 * 29, end: now + 3600, title: "Event 1"),
            .make(id: "2", start: now + 60 * 30, end: now + 3600, title: "Event 2")
        ])

        #expect(viewModel.title.lastValue() == "Event 1")
        #expect(viewModel.time.lastValue() == "1h left")
    }

    @Test func testNextEvent_isInProgress_withCloserUpcomingEvent_shouldShowUpcoming() {

        let viewModel = makeViewModel(type: .event)

        calendarService.changeEvents([
            .make(id: "1", start: now - 60 * 31, end: now + 3600, title: "Event 1"),
            .make(id: "2", start: now + 60 * 30, end: now + 3600, title: "Event 2")
        ])

        #expect(viewModel.title.lastValue() == "Event 2")
        #expect(viewModel.time.lastValue() == "in 30m")
    }

    @Test func testNextEvent_isInProgress_withCloserOngoingEvent_shouldShowClosest() {

        let viewModel = makeViewModel(type: .event)

        calendarService.changeEvents([
            .make(id: "1", start: now - 60 * 40, end: now + 60 * 10, title: "Event 1"),
            .make(id: "2", start: now - 60 * 30, end: now + 60 * 5, title: "Event 2")
        ])

        #expect(viewModel.title.lastValue() == "Event 2")
        #expect(viewModel.time.lastValue() == "5m left")
    }

    @Test func testNextEvent_isInProgress_withCloserEventEnded_shouldShowPreviousOngoingEvent() {

        let viewModel = makeViewModel(type: .event)

        calendarService.changeEvents([
            .make(id: "1", start: now - 60 * 40, end: now + 60 * 10, title: "Event 1"),
            .make(id: "2", start: now - 60 * 30, end: now /* ended */, title: "Event 2")
        ])

        #expect(viewModel.title.lastValue() == "Event 1")
        #expect(viewModel.time.lastValue() == "10m left")
    }

    @Test func testNextEvent_isReminder() {

        let viewModel = makeViewModel(type: .reminder)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 6000, type: .reminder(completed: false))
        ])

        #expect(time == "in 1h 40m")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "in 1h 39m")
    }

    @Test func testNextEvent_isPast_isReminder() {

        let viewModel = makeViewModel(type: .reminder)

        var time: String?

        let start = now

        dateProvider.now.addTimeInterval(6000)

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: start, type: .reminder(completed: false))
        ])

        #expect(time == "1h 40m ago")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "1h 41m ago")
    }

    @Test func testNextEvent_becomesPast_isReminder() {

        let viewModel = makeViewModel(type: .reminder)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: dateProvider.now + 30, type: .reminder(completed: false))
        ])

        #expect(time == "in 30s")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        #expect(time == "30s ago")
    }

    @Test func testNextEvent_isSortedByDate_isReminder() {

        let viewModel = makeViewModel(type: .reminder)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 1, title: "Reminder 2", type: .reminder(completed: false)),
            .make(start: now, title: "Reminder 1", type: .reminder(completed: false))
        ])

        #expect(title == "Reminder 1")
    }

    @Test func testNextEvent_skipped_fromContextMenu() throws {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(id: "1", start: now, end: now + 1, title: "Event 1", type: .event(.maybe)),
            .make(id: "2", start: now + 1, end: now + 2, title: "Event 2", type: .event(.accepted))
        ])

        #expect(title == "Event 1")
        #expect(hasEvent == true)

        try #require(viewModel.makeContextMenuViewModel() as? EventOptionsViewModel).triggerAction(.skip)

        scheduler.advance(.milliseconds(1))

        #expect(title == "Event 2")
        #expect(hasEvent == true)

        try #require(viewModel.makeContextMenuViewModel() as? EventOptionsViewModel).triggerAction(.skip)

        scheduler.advance(.milliseconds(1))

        #expect(hasEvent == false)
    }

    @Test func testNextEvent_skipped_fromEventDetails() throws {

        let viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(id: "1", start: now, end: now + 1, title: "Event 1", type: .event(.maybe)),
            .make(id: "2", start: now + 1, end: now + 2, title: "Event 2", type: .event(.accepted))
        ])

        #expect(title == "Event 1")
        #expect(hasEvent == true)

        try #require(viewModel.makeDetailsViewModel()).skipTapped.onNext(())

        scheduler.advance(.milliseconds(1))

        #expect(title == "Event 2")
        #expect(hasEvent == true)

        try #require(viewModel.makeDetailsViewModel()).skipTapped.onNext(())

        scheduler.advance(.milliseconds(1))

        #expect(hasEvent == false)
    }
}
