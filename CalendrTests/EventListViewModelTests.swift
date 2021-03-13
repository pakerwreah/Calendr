//
//  EventListViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class EventListViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateSubject = PublishSubject<Date>()
    let eventsSubject = PublishSubject<[EventModel]>()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventListSettings()
    lazy var scheduler = TrackedHistoricalScheduler(initialClock: dateProvider.now)

    lazy var viewModel = EventListViewModel(
        dateObservable: dateSubject,
        eventsObservable: eventsSubject,
        dateProvider: dateProvider,
        calendarService: calendarService,
        workspace: workspace,
        settings: settings,
        scheduler: scheduler
    )

    enum EventListItemTest: Equatable {
        case section(String)
        case interval(String)
        case event(String)
    }

    var eventListItems: [EventListItemTest]?

    func testEvents(adding value: Int = 0, _ component: Calendar.Component = .day) -> [EventModel] {

        let date = dateProvider.calendar.date(byAdding: component, value: value, to: dateProvider.now)!
        let yesterday = dateProvider.calendar.date(byAdding: .day, value: -1, to: date)!

        return [
            .make(start: date + 70, end: date + 200, title: "Event 1", isAllDay: false),
            .make(start: date + 70, end: date + 100, title: "Event 2", isAllDay: false),
            .make(start: date, end: date + 10, title: "All day 1", isAllDay: true),
            .make(start: date, end: date + 10, title: "Event 3", isAllDay: false),
            .make(start: date, end: date + 10, title: "All day 2", isAllDay: true),
            .make(start: yesterday, end: date + 10, title: "Multi day", isAllDay: false)
        ]
    }

    override func setUp() {

        viewModel.asObservable()
            .bind { [weak self] in
                self?.eventListItems = $0.map { item in
                    switch item {
                    case .event(let viewModel):
                        return .event(viewModel.title)

                    case .section(let text):
                        return .section(text)

                    case .interval(let text, _):
                        return .interval(text)
                    }
                }
            }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
    }

    func testEventList_noEvents_shouldNotShowAnySection() {

        eventsSubject.onNext([])

        XCTAssertEqual(eventListItems, [])
    }

    func testEventList_onlyAllDay_shouldNotShowTodaySection() {

        eventsSubject.onNext(testEvents().filter(\.isAllDay))

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
        ])
    }

    func testEventList_noAllDay_shouldNotShowAllDaySection() {

        eventsSubject.onNext(testEvents().filter(\.isAllDay.isFalse))

        XCTAssertEqual(eventListItems, [
            .section("Today"),
            .event("Multi day"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_isToday_shouldShowTodaySection() {

        eventsSubject.onNext(testEvents())

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Multi day"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_isNotToday_shouldShowDateSection() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        eventsSubject.onNext(testEvents())

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("2021-01-02"),
            .event("Multi day"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_withHidePastEventsEnabled_isNotToday_shouldNotHideEvents() {

        dateSubject.onNext(.make(year: 2020, month: 12, day: 31))
        eventsSubject.onNext(testEvents())
        settings.togglePastEvents.onNext(false)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("2020-12-31"),
            .event("Multi day"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_withHidePastEventsEnabled_isToday_shouldHidePastEvents() {

        eventsSubject.onNext(testEvents())
        settings.togglePastEvents.onNext(false)

        dateProvider.add(1, .minute)
        scheduler.advance(1, .minute)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Event 2"),
            .event("Event 1")
        ])

        dateProvider.add(1, .minute)
        scheduler.advance(1, .minute)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Event 1")
        ])
    }

    func testEventList_withFadePastEventsEnabled_shouldFadePastSections() {

        let events = testEvents()
        let lastDate = events.filter(\.isAllDay.isFalse).max(by: { $0.end < $1.end })!.end
        let start = dateProvider.calendar.date(byAdding: .minute, value: 90, to: lastDate)!

        eventsSubject.onNext(events + [
            .make(start: start, end: start + 1, title: "Event 4")
        ])

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Multi day"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1"),
            .interval("1h 30m"),
            .event("Event 4")
        ])

        var sectionsFaded: [Bool]?

        viewModel.asObservable()
            .flatMap {
                Observable.combineLatest(
                    $0.compactMap { item -> Observable<Bool>? in
                        switch item {
                        case .interval(_, let fade):
                            return fade
                        default:
                            return nil
                        }
                    }
                )
            }
            .bind {
                sectionsFaded = $0
            }
            .disposed(by: disposeBag)

        XCTAssertEqual(sectionsFaded, [false, false])

        dateProvider.add(1, .hour)
        scheduler.advance(1, .hour)

        XCTAssertEqual(sectionsFaded, [true, false])

        dateProvider.add(1, .hour)
        scheduler.advance(1, .hour)

        XCTAssertEqual(sectionsFaded, [true, true])
    }

    func testEventList_withFadePastEventsEnabled_shouldNotScheduleRefreshes() {

        eventsSubject.onNext(testEvents())

        XCTAssertTrue(scheduler.log.isEmpty)
    }

    func testEventList_withHidePastEventsEnabled_isNotToday_shouldNotScheduleRefreshes() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        eventsSubject.onNext(testEvents())
        settings.togglePastEvents.onNext(false)

        XCTAssertTrue(scheduler.log.isEmpty)
    }

    func testEventList_withHidePastEventsEnabled_withExactSecond_shouldScheduleRefreshesCorrectly() {

        let events = testEvents()
        eventsSubject.onNext(events)
        settings.togglePastEvents.onNext(false)

        XCTAssertFalse(scheduler.log.isEmpty)
        XCTAssertTrue(zip(scheduler.log, events.filter(\.isAllDay.isFalse).map(\.end)).allSatisfy(>))
    }

    func testEventList_withHidePastEventsEnabled_withPartialSecond_shouldScheduleRefreshesCorrectly() {

        let events = testEvents()

        dateProvider.now.addTimeInterval(0.1)
        scheduler.advanceTo(dateProvider.now)

        eventsSubject.onNext(events)

        settings.togglePastEvents.onNext(false)

        XCTAssertFalse(scheduler.log.isEmpty)
        XCTAssertTrue(zip(scheduler.log, events.filter(\.isAllDay.isFalse).map(\.end)).allSatisfy(>))
    }
}
