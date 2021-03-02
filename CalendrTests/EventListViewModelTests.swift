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

    let eventsSubject = PublishSubject<[EventModel]>()

    let dateProvider = MockDateProvider()
    let workspaceProvider = MockWorkspaceProvider()
    let settings = MockEventSettings()
    let scheduler = TestScheduler()

    lazy var viewModel = EventListViewModel(
        eventsObservable: eventsSubject,
        dateProvider: dateProvider,
        workspaceProvider: workspaceProvider,
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

        let now = dateProvider.calendar.date(byAdding: component, value: value, to: dateProvider.now)!

        return [
            .make(start: now + 70, end: now + 200, title: "Event 1", isAllDay: false),
            .make(start: now + 70, end: now + 100, title: "Event 2", isAllDay: false),
            .make(start: now, end: now + 10, title: "All day 1", isAllDay: true),
            .make(start: now, end: now + 10, title: "Event 3", isAllDay: false),
            .make(start: now, end: now + 10, title: "All day 2", isAllDay: true)
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
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_isNotToday_shouldShowDateSection() {

        eventsSubject.onNext(testEvents(adding: 1, .day))

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("2021-01-02"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])
    }

    func testEventList_withHidePastEventsEnabled_isNotToday_shouldNotHideEvents() {

        eventsSubject.onNext(testEvents(adding: 1, .day))

        settings.togglePastEvents.onNext(false)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("2021-01-02"),
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
        scheduler.advance(by: .seconds(60))

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Event 2"),
            .event("Event 1")
        ])

        dateProvider.add(1, .minute)
        scheduler.advance(by: .seconds(60))

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
        scheduler.advance(by: .seconds(60 * 60))

        XCTAssertEqual(sectionsFaded, [true, false])

        dateProvider.add(1, .hour)
        scheduler.advance(by: .seconds(60 * 60))

        XCTAssertEqual(sectionsFaded, [true, true])
    }
}
