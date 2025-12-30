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
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventListSettings()
    let localStorage = MockLocalStorageProvider()

    let scheduler = HistoricalScheduler()
    let eventsScheduler = HistoricalScheduler()
    lazy var refreshScheduler = TrackedHistoricalScheduler(initialClock: dateProvider.now)

    lazy var viewModel = EventListViewModel(
        eventsObservable: Observable.combineLatest(dateSubject, eventsSubject).map { date, events in
            DateEvents(date: date, events: events)
        },
        isShowingDetailsModal: .init(value: false),
        dateProvider: dateProvider,
        calendarService: calendarService,
        geocoder: geocoder,
        weatherService: weatherService,
        workspace: workspace,
        localStorage: localStorage,
        settings: settings,
        scheduler: scheduler,
        refreshScheduler: refreshScheduler,
        eventsScheduler: eventsScheduler
    )

    enum EventListItemTest: Equatable {
        case section(String)
        case interval(String)
        case event(String)
    }

    var eventListItems: [EventListItemTest]?

    func testEvents(baseDate: Date? = nil) -> [EventModel] {

        let date = baseDate ?? dateProvider.now
        let yesterday = dateProvider.calendar.date(byAdding: .day, value: -1, to: date)!

        return [
            .make(start: date + 70, end: date + 200, title: "Event 1", isAllDay: false, calendar: .color(.red)),
            .make(start: date + 70, end: date + 100, title: "Event 2", isAllDay: false, calendar: .color(.red)),
            .make(start: date, end: date + 10, title: "All day 1", isAllDay: true, calendar: .color(.red)),
            .make(start: date, end: date + 10, title: "Event 3", isAllDay: false, calendar: .color(.yellow)),
            .make(start: date, end: date + 10, title: "All day 2", isAllDay: true, calendar: .color(.yellow)),
            .make(start: yesterday, end: date + 10, title: "Multi day", isAllDay: false, calendar: .color(.blue))
        ]
    }

    override func setUp() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        viewModel.items
            .bind { [weak self] in
                self?.eventListItems = $0.map { item in
                    switch item {
                    case .event(let viewModel):
                        return .event(viewModel.title)

                    case .section(let text):
                        return .section(text)

                    case .interval(let viewModel):
                        return .interval(viewModel.text.lastValue() ?? "")
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

        let summary = EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [], count: 0)
        )
        XCTAssertEqual(viewModel.summary.lastValue(), summary)
    }

    func testEventList_noAllDay_shouldNotShowAllDaySection() {

        eventsSubject.onNext(testEvents().filter(\.isAllDay.isFalse))

        XCTAssertEqual(eventListItems, [
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Today"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [], count: 0),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_isToday_shouldShowTodaySection() {

        eventsSubject.onNext(testEvents())

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Today"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_isNotToday_shouldShowDateSection() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        eventsSubject.onNext(testEvents())

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Friday, Jan 1"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_withHidePastEventsEnabled_isNotToday_shouldNotHideEvents() {

        let selectedDate: Date = .make(year: 2020, month: 12, day: 31)
        dateSubject.onNext(selectedDate)
        eventsSubject.onNext(testEvents(baseDate: selectedDate))
        settings.togglePastEvents.onNext(false)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Wednesday, Dec 30"),
            .event("Multi day"),
            .section("Thursday, Dec 31"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_withHidePastEventsEnabled_isToday_shouldHidePastEvents() {

        eventsSubject.onNext(testEvents())
        settings.togglePastEvents.onNext(false)

        dateProvider.add(1, .minute)
        refreshScheduler.advance(1, .minute)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.red], count: 2)
        ))

        dateProvider.add(1, .minute)
        refreshScheduler.advance(1, .minute)

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Today"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.red], count: 1)
        ))
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
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Today"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1"),
            .interval("1h 30m"),
            .event("Event 4")
        ])

        var sectionsFaded: [Bool]?

        viewModel.items
            .flatMap {
                Observable.combineLatest(
                    $0.compactMap { item -> Observable<Bool>? in
                        switch item {
                        case .interval(let viewModel):
                            return viewModel.fade
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

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red, .clear], count: 5)
        ))

        dateProvider.add(1, .hour)
        eventsScheduler.advance(1, .hour)

        XCTAssertEqual(sectionsFaded, [true, false])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.clear], count: 1)
        ))

        dateProvider.add(1, .hour)
        eventsScheduler.advance(1, .hour)

        XCTAssertEqual(sectionsFaded, [true, true])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [], count: 0)
        ))
    }

    func testEventList_withFadePastEventsEnabled_shouldNotScheduleRefreshes() {

        eventsSubject.onNext(testEvents())

        XCTAssertTrue(refreshScheduler.log.isEmpty)
    }

    func testEventList_withHidePastEventsEnabled_isNotToday_shouldNotScheduleRefreshes() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        eventsSubject.onNext(testEvents())
        settings.togglePastEvents.onNext(false)

        XCTAssertTrue(refreshScheduler.log.isEmpty)
    }

    func testEventList_withHidePastEventsEnabled_withExactSecond_shouldScheduleRefreshesCorrectly() {

        let events = testEvents()
        eventsSubject.onNext(events)
        settings.togglePastEvents.onNext(false)

        XCTAssertFalse(refreshScheduler.log.isEmpty)
        XCTAssertTrue(zip(refreshScheduler.log, events.filter(\.isAllDay.isFalse).map(\.end)).allSatisfy(>))
    }

    func testEventList_withHidePastEventsEnabled_withPartialSecond_shouldScheduleRefreshesCorrectly() {

        let events = testEvents()

        dateProvider.now.addTimeInterval(0.1)
        refreshScheduler.advanceTo(dateProvider.now)

        eventsSubject.onNext(events)

        settings.togglePastEvents.onNext(false)

        XCTAssertFalse(refreshScheduler.log.isEmpty)
        XCTAssertTrue(zip(refreshScheduler.log, events.filter(\.isAllDay.isFalse).map(\.end)).allSatisfy(>))
    }

    func testEventList_withOverdueReminders_shouldShowInDedicatedSections() {

        let yesterday = dateProvider.calendar.date(byAdding: .day, value: -1, to: dateProvider.now)!
        let twoDaysAgo = dateProvider.calendar.date(byAdding: .day, value: -2, to: dateProvider.now)!

        eventsSubject.onNext(
            testEvents() +
            [
                .make(start: yesterday, title: "Overdue 1", type: .reminder(completed: false), calendar: .color(.purple)),
                .make(start: yesterday + 10, title: "Overdue 2", type: .reminder(completed: false), calendar: .color(.green)),
                .make(start: twoDaysAgo, title: "All day overdue", isAllDay: true, type: .reminder(completed: false), calendar: .color(.green)),
            ]
        )

        XCTAssertEqual(eventListItems, [
            .section("2 days ago"),
            .event("All day overdue"),
            .section("Yesterday"),
            .event("Overdue 1"),
            .event("Overdue 2"),
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Today"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [.green, .purple], count: 3),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_withOverdueReminders_withShowOverdueDisabled_shouldNotShowOverdueReminders() {

        settings.toggleOverdueReminders.onNext(false)

        let yesterday = dateProvider.calendar.date(byAdding: .day, value: -1, to: dateProvider.now)!
        let twoDaysAgo = dateProvider.calendar.date(byAdding: .day, value: -2, to: dateProvider.now)!

        eventsSubject.onNext(
            testEvents() +
            [
                .make(start: yesterday, title: "Overdue 1", type: .reminder(completed: false), calendar: .color(.purple)),
                .make(start: yesterday + 10, title: "Overdue 2", type: .reminder(completed: false), calendar: .color(.green)),
                .make(start: twoDaysAgo, title: "All day overdue", isAllDay: true, type: .reminder(completed: false), calendar: .color(.green)),
            ]
        )

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day 1"),
            .event("All day 2"),
            .section("Thursday, Dec 31"),
            .event("Multi day"),
            .section("Today"),
            .event("Event 3"),
            .interval("1m"),
            .event("Event 2"),
            .event("Event 1")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.blue, .yellow, .red], count: 4)
        ))
    }

    func testEventList_withOverdueReminders_isNotToday_shouldShowNormally() {

        let date = dateProvider.calendar.date(byAdding: .day, value: -1, to: dateProvider.now)!
        dateSubject.onNext(date)

        settings.togglePastEvents.onNext(false)

        eventsSubject.onNext(
            [
                .make(start: date, end: date + 10, title: "Event 1", calendar: .color(.red)),
                .make(start: date + 60, end: date + 120, title: "Event 2", calendar: .color(.red)),
                .make(start: date + 200, title: "Overdue", type: .reminder(completed: false), calendar: .color(.yellow)),
                .make(start: date + 300, title: "Completed", type: .reminder(completed: true), calendar: .color(.yellow)),
                .make(start: date, title: "All day event", isAllDay: true, calendar: .color(.red)),
                .make(start: date, title: "All day overdue", isAllDay: true, type: .reminder(completed: false), calendar: .color(.red))
            ]
        )

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day event"),
            .event("All day overdue"),
            .section("Thursday, Dec 31"),
            .event("Event 1"),
            .event("Event 2"),
            .interval("1m"),
            .event("Overdue"),
            .event("Completed")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red], count: 2),
            today: .init(colors: [.red, .yellow], count: 4)
        ))
    }

    func testEventList_withCompletedReminders_isToday_shouldShowNormally() {

        let date = dateProvider.now

        eventsSubject.onNext(
            [
                .make(start: date, end: date + 10, title: "Event 1", calendar: .color(.red)),
                .make(start: date + 60, end: date + 120, title: "Event 2", calendar: .color(.red)),
                .make(start: date + 200, title: "Reminder 1", type: .reminder(completed: true), calendar: .color(.yellow)),
                .make(start: date + 300, title: "Reminder 2", type: .reminder(completed: false), calendar: .color(.green)),
                .make(start: date, title: "All day event", isAllDay: true, calendar: .color(.red)),
                .make(start: date, title: "All day overdue", isAllDay: true, type: .reminder(completed: false), calendar: .color(.yellow))
            ]
        )

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day event"),
            .event("All day overdue"),
            .section("Today"),
            .event("Event 1"),
            .event("Event 2"),
            .interval("1m"),
            .event("Reminder 1"),
            .event("Reminder 2")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.red, .green], count: 3)
        ))
    }


    func testEventList_withCompletedReminders_withHidePastEventsEnabled_isToday_shouldHideCompleted() {

        let date = dateProvider.now

        settings.togglePastEvents.onNext(false)

        eventsSubject.onNext(
            [
                .make(start: date, end: date + 10, title: "Event 1", calendar: .color(.red)),
                .make(start: date + 60, end: date + 120, title: "Event 2", calendar: .color(.red)),
                .make(start: date + 200, title: "Reminder 1", type: .reminder(completed: true), calendar: .color(.yellow)),
                .make(start: date + 300, title: "Reminder 2", type: .reminder(completed: false), calendar: .color(.green)),
                .make(start: date, title: "All day event", isAllDay: true, calendar: .color(.red)),
                .make(start: date, title: "All day overdue", isAllDay: true, type: .reminder(completed: false), calendar: .color(.yellow))
            ]
        )

        XCTAssertEqual(eventListItems, [
            .section("All day"),
            .event("All day event"),
            .event("All day overdue"),
            .section("Today"),
            .event("Event 1"),
            .event("Event 2"),
            .interval("3m"),
            .event("Reminder 2")
        ])

        XCTAssertEqual(viewModel.summary.lastValue(), EventListSummary(
            overdue: .init(colors: [], count: 0),
            allday: .init(colors: [.red, .yellow], count: 2),
            today: .init(colors: [.red, .green], count: 3)
        ))
    }

    func testEventList_withUpcomingEvent_shouldShowRelativeTime() {

        let date = dateProvider.now

        eventsSubject.onNext([
            .make(start: date - 5 * 60, end: date - 4 * 60, title: "Event 1"),
            .make(start: date - 2 * 60, end: date - 1 * 60, title: "Event 2"),
            .make(start: date + 1 * 60, end: date + 2 * 60, title: "Event 3"),
            .make(start: date + 5 * 60, end: date + 8 * 60, title: "Event 4"),
        ])

        XCTAssertEqual(eventListItems, [
            .section("Thursday, Dec 31"),
            .event("Event 1"),
            .interval("2m"),
            .event("Event 2"),
            .section("Today"),
            .event("Event 3"),
            .interval("3m"),
            .event("Event 4"),
        ])
    }
}

private extension CalendarModel {

    static func color(_ color: NSColor) -> CalendarModel {
        .make(color: color)
    }
}
