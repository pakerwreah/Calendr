//
//  NextEventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class NextEventViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let calendarsSubject = BehaviorSubject<[String]>(value: [])

    let userDefaults = UserDefaults(suiteName: className())!
    let settings = MockNextEventSettings()
    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let screenProvider = MockScreenProvider()
    let scheduler = HistoricalScheduler()

    lazy var viewModel = makeViewModel(type: .event)

    func makeViewModel(type: NextEventType) -> NextEventViewModel {
        .init(
            type: type,
            userDefaults: userDefaults,
            settings: settings,
            nextEventCalendars: calendarsSubject,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: .dummy(),
            scheduler: scheduler
        )
    }

    var now: Date {
        dateProvider.now
    }

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testSaveStatusItemPreferredPosition() {

        let key = "\(Prefs.statusItemPreferredPosition) \(StatusItemName.event)"
        userDefaults.set(123, forKey: key)
        viewModel.saveStatusItemPreferredPosition()
        XCTAssertEqual(userDefaults.integer(forKey: "saved \(key)"), 123)
    }

    func testRestoreStatusItemPreferredPosition() {

        let key = "\(Prefs.statusItemPreferredPosition) \(StatusItemName.event)"
        XCTAssertEqual(userDefaults.integer(forKey: key), 0)
        userDefaults.set(123, forKey: "saved \(key)")
        viewModel.restoreStatusItemPreferredPosition()
        XCTAssertEqual(userDefaults.integer(forKey: key), 123)
    }

    func testNextEvent_noEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 2, end: now - 1)
        ])

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEvent_hasEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        XCTAssertEqual(hasEvent, true)
    }

    func testNextEvent_isNotEnabled_noEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1)
        ])

        XCTAssertEqual(hasEvent, true)

        settings.toggleStatusItem.onNext(false)

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEvent_checkRange() {

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

        XCTAssertEqual(hasEvent, true)

        start += 1

        calendarService.changeEvents([
            .make(start: start, end: start + 1)
        ])

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEventLength() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event with a text")
        ])

        settings.eventStatusItemLengthObserver.onNext(30)

        XCTAssertEqual(title, "This is an event with a text")

        settings.eventStatusItemLengthObserver.onNext(10)

        XCTAssertEqual(title, "This is an...")
    }

    func testNextEventLengthWithNotch() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, title: "This is an event with a text")
        ])

        settings.eventStatusItemLengthObserver.onNext(30)

        XCTAssertEqual(title, "This is an event with a text")

        settings.toggleEventStatusItemDetectNotch.onNext(true)

        XCTAssertEqual(title, "This is an event with a text")

        screenProvider.screenObserver.onNext(MockScreen(hasNotch: true))

        XCTAssertEqual(title, "This is an even.")

        settings.eventStatusItemLengthObserver.onNext(10)

        XCTAssertEqual(title, "This is an.")
    }

    func testNextEvent_barStyle() {

        var style: EventBarStyle?

        viewModel.barStyle
            .bind { style = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([.make(start: now, type: .event(.accepted))])
        XCTAssertEqual(style, .filled)

        calendarService.changeEvents([.make(start: now, type: .event(.maybe))])
        XCTAssertEqual(style, .bordered)
    }

    func testNextEvent_barColor() {

        var color: NSColor?

        viewModel.barColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, .white)
    }

    func testNextEvent_isNotInProgress_backgroundColor() {

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 1, end: now + 2, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, .clear)
    }

    func testNextEvent_isInProgress_backgroundColor() {

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now - 1, end: now + 1, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, NSColor.white.withAlphaComponent(0.2))
    }

    func testNextEvent_isAllDay_shouldNotAppear() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", isAllDay: true),
            .make(start: now + 1, end: now + 2, title: "Event 2", isAllDay: false)
        ])

        XCTAssertEqual(title, "Event 2")
    }

    func testNextEvent_isPending_shouldNotAppear() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", type: .event(.pending)),
            .make(start: now + 1, end: now + 2, title: "Event 2", type: .event(.accepted))
        ])

        XCTAssertEqual(title, "Event 2")
    }

    func testNextEvent_isNotInProgress_startsIn30Seconds() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 30, end: now + 60)
        ])

        XCTAssertEqual(time, "in 30s")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 29s")
    }

    func testNextEvent_isNotInProgress_startsInLessThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 59, end: now + 60)
        ])

        XCTAssertEqual(time, "in 1m")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 1m")

        dateProvider.now.addTimeInterval(28)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 30s")
    }

    func testNextEvent_isNotInProgress_startsIn1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 60, end: now + 70)
        ])

        XCTAssertEqual(time, "in 1m")
    }

    func testNextEvent_isNotInProgress_startsInMoreThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 65, end: now + 70)
        ])

        XCTAssertEqual(time, "in 2m")

        dateProvider.now.addTimeInterval(5)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 1m")
    }

    func testNextEvent_isNotInProgress_startsIn1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 3600, end: now + 3610)
        ])

        XCTAssertEqual(time, "in 1h")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 59m")
    }

    func testNextEvent_isNotInProgress_startsInMoreThan1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 6000, end: now + 6010)
        ])

        XCTAssertEqual(time, "in 1h 40m")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 1h 39m")
    }

    func testNextEvent_isInProgress_endsIn30Seconds() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 30)
        ])

        XCTAssertEqual(time, "30s left")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "29s left")
    }

    func testNextEvent_isInProgress_endsInLessThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 59)
        ])

        XCTAssertEqual(time, "1m left")

        dateProvider.now.addTimeInterval(1)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "1m left")

        dateProvider.now.addTimeInterval(28)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "30s left")
    }

    func testNextEvent_isInProgress_endsIn1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 60)
        ])

        XCTAssertEqual(time, "1m left")
    }

    func testNextEvent_isInProgress_endsInMoreThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 65)
        ])

        XCTAssertEqual(time, "2m left")

        dateProvider.now.addTimeInterval(5)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "1m left")
    }

    func testNextEvent_isInProgress_endsIn1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 3600)
        ])

        XCTAssertEqual(time, "1h left")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "59m left")
    }

    func testNextEvent_isInProgress_endsInMoreThan1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 6000)
        ])

        XCTAssertEqual(time, "1h 40m left")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "1h 39m left")
    }

    func testNextEvent_isReminder() {

        viewModel = makeViewModel(type: .reminder)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 6000, type: .reminder)
        ])

        XCTAssertEqual(time, "in 1h 40m")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "in 1h 39m")
    }

    func testNextEvent_isPast_isReminder() {

        viewModel = makeViewModel(type: .reminder)

        var time: String?

        let start = now

        dateProvider.now.addTimeInterval(6000)

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: start, type: .reminder)
        ])

        XCTAssertEqual(time, "1h 40m ago")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "1h 41m ago")
    }

    func testNextEvent_becomesPast_isReminder() {

        viewModel = makeViewModel(type: .reminder)

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: dateProvider.now + 30, type: .reminder)
        ])

        XCTAssertEqual(time, "in 30s")

        dateProvider.now.addTimeInterval(60)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(time, "30s ago")
    }

    func testNextEvent_isSortedByDate_isReminder() {

        viewModel = makeViewModel(type: .reminder)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now + 1, title: "Reminder 2", type: .reminder),
            .make(start: now, title: "Reminder 1", type: .reminder)
        ])

        XCTAssertEqual(title, "Reminder 1")
    }

    func testNextEvent_skipped_fromContextMenu() {

        viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", type: .event(.maybe)),
            .make(start: now + 1, end: now + 2, title: "Event 2", type: .event(.accepted))
        ])

        let contextMenu = viewModel.makeContextMenuViewModel() as? EventOptionsViewModel
        XCTAssertNotNil(contextMenu)

        XCTAssertEqual(title, "Event 1")
        XCTAssertEqual(hasEvent, true)

        contextMenu?.triggerAction(.skip)

        XCTAssertEqual(title, "Event 2")
        XCTAssertEqual(hasEvent, true)

        contextMenu?.triggerAction(.skip)

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEvent_skipped_fromEventDetails() {

        viewModel = makeViewModel(type: .event)

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        calendarService.changeEvents([
            .make(start: now, end: now + 1, title: "Event 1", type: .event(.maybe)),
            .make(start: now + 1, end: now + 2, title: "Event 2", type: .event(.accepted))
        ])

        let viewModel = viewModel.makeDetailsViewModel()
        XCTAssertNotNil(viewModel)

        XCTAssertEqual(title, "Event 1")
        XCTAssertEqual(hasEvent, true)

        viewModel?.skipTapped.onNext(())

        XCTAssertEqual(title, "Event 2")
        XCTAssertEqual(hasEvent, true)

        viewModel?.skipTapped.onNext(())

        XCTAssertEqual(hasEvent, false)
    }
}
