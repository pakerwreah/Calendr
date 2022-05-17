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

    let eventsSubject = PublishSubject<[EventModel]>()

    let settings = MockNextEventSettings()
    let dateProvider = MockDateProvider()
    let screenProvider = MockScreenProvider()

    lazy var viewModel = NextEventViewModel(
        settings: settings,
        eventsObservable: eventsSubject,
        dateProvider: dateProvider,
        screenProvider: screenProvider
    )

    var now: Date {
        dateProvider.now
    }

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testNextEvent_noEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now - 2, end: now - 1)
        ])

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEvent_hasEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 1)
        ])

        XCTAssertEqual(hasEvent, true)
    }

    func testNextEvent_isNotEnabled_noEvent() {

        var hasEvent: Bool?

        viewModel.hasEvent
            .bind { hasEvent = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 1)
        ])

        XCTAssertEqual(hasEvent, true)

        settings.toggleStatusItem.onNext(false)

        XCTAssertEqual(hasEvent, false)
    }

    func testNextEventLength() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(title: "This is an event with a text")
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

        eventsSubject.onNext([
            .make(title: "This is an event with a text")
        ])

        settings.eventStatusItemLengthObserver.onNext(30)

        XCTAssertEqual(title, "This is an event with a text")

        settings.toggleEventStatusItemDetectNotch.onNext(true)

        XCTAssertEqual(title, "This is an event with a text")

        screenProvider.hasNotchObserver.onNext(true)

        XCTAssertEqual(title, "This is an even.")

        settings.eventStatusItemLengthObserver.onNext(10)

        XCTAssertEqual(title, "This is an.")
    }

    func testNextEvent_barColor() {

        var color: NSColor?

        viewModel.barColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 1, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, .white)
    }

    func testNextEvent_isNotInProgress_backgroundColor() {

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 1, end: now + 2, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, .clear)
    }

    func testNextEvent_isInProgress_backgroundColor() {

        var color: NSColor?

        viewModel.backgroundColor
            .bind { color = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now - 1, end: now + 1, calendar: .make(color: .white))
        ])

        XCTAssertEqual(color, NSColor.white.withAlphaComponent(0.2))
    }

    func testNextEvent_isAllDay_shouldNotAppear() {

        var title: String?

        viewModel.title
            .bind { title = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
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

        eventsSubject.onNext([
            .make(start: now, end: now + 1, title: "Event 1", isPending: true),
            .make(start: now + 1, end: now + 2, title: "Event 2", isPending: false)
        ])

        XCTAssertEqual(title, "Event 2")
    }

    func testNextEvent_isNotInProgress_startsIn30Seconds() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 30, end: now + 60)
        ])

        XCTAssertEqual(time, "in 30s")
    }

    func testNextEvent_isNotInProgress_startsInLessThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 59, end: now + 60)
        ])

        XCTAssertEqual(time, "in 1m")
    }

    func testNextEvent_isNotInProgress_startsIn1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 60, end: now + 70)
        ])

        XCTAssertEqual(time, "in 1m")
    }

    func testNextEvent_isNotInProgress_startsInMoreThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 65, end: now + 70)
        ])

        XCTAssertEqual(time, "in 2m")
    }

    func testNextEvent_isNotInProgress_startsIn1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 3600, end: now + 3610)
        ])

        XCTAssertEqual(time, "in 1h")
    }

    func testNextEvent_isNotInProgress_startsInMoreThan1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 6000, end: now + 6010)
        ])

        XCTAssertEqual(time, "in 1h 40m")
    }

    func testNextEvent_isInProgress_endsIn30Seconds() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 30)
        ])

        XCTAssertEqual(time, "30s left")
    }

    func testNextEvent_isInProgress_endsInLessThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 59)
        ])

        XCTAssertEqual(time, "1m left")
    }

    func testNextEvent_isInProgress_endsIn1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 60)
        ])

        XCTAssertEqual(time, "1m left")
    }

    func testNextEvent_isInProgress_endsInMoreThan1Minute() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 65)
        ])

        XCTAssertEqual(time, "2m left")
    }

    func testNextEvent_isInProgress_endsIn1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 3600)
        ])

        XCTAssertEqual(time, "1h left")
    }

    func testNextEvent_isInProgress_endsInMoreThan1Hour() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now, end: now + 6000)
        ])

        XCTAssertEqual(time, "1h 40m left")
    }

    func testNextEvent_isReminder() {

        var time: String?

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: now + 6000, type: .reminder)
        ])

        XCTAssertEqual(time, "in 1h 40m")
    }

    func testNextEvent_isPast_isReminder() {

        var time: String?

        let start = now

        dateProvider.now.addTimeInterval(6000)

        viewModel.time
            .bind { time = $0 }
            .disposed(by: disposeBag)

        eventsSubject.onNext([
            .make(start: start, type: .reminder)
        ])

        XCTAssertEqual(time, "1h 40m ago")
    }
}

