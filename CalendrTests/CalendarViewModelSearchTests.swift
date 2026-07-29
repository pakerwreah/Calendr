//
//  CalendarViewModelSearchTests.swift
//  CalendrTests
//
//  Created by Paker on 29/07/2026.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class CalendarViewModelSearchTests {

    private let disposeBag = DisposeBag()

    private let searchSubject = BehaviorSubject<String>(value: "")
    private let dateSubject = PublishSubject<Date>()
    private let hoverSubject = PublishSubject<Date?>()
    private let keyboardModifiers = BehaviorSubject<NSEvent.ModifierFlags>(value: [])
    private let enabledCalendars = BehaviorSubject<[String]>(value: [])

    private let dateProvider = MockDateProvider()
    private let settings = MockCalendarSettings()
    private let scheduler = HistoricalScheduler()

    private lazy var calendarService = MockCalendarServiceProvider(dateProvider: dateProvider)
    private lazy var viewModel = CalendarViewModel(
        searchObservable: searchSubject,
        dateObservable: dateSubject,
        hoverObservable: hoverSubject,
        keyboardModifiers: keyboardModifiers,
        enabledCalendars: enabledCalendars,
        calendarService: calendarService,
        dateProvider: dateProvider,
        settings: settings,
        scheduler: scheduler
    )

    private var eventList: DateEvents?

    init() {

        let calendar = CalendarModel.make(id: "calendar", account: "Account", title: "Calendar", color: .blue)

        calendarService.m_events = [
            .make(start: .make(year: 2020, month: 12, day: 24), title: "Find outside leading margin", calendar: calendar),
            .make(start: .make(year: 2020, month: 12, day: 25), title: "Find leading margin", calendar: calendar),
            .make(start: .make(year: 2021, month: 1, day: 1), title: "Find first day", calendar: calendar),
            .make(start: .make(year: 2021, month: 6, day: 15), title: "Find middle of year", calendar: calendar),
            .make(start: .make(year: 2021, month: 12, day: 31), title: "Find last day", calendar: calendar),
            .make(start: .make(year: 2022, month: 2, day: 1), title: "Find trailing margin", calendar: calendar),
            .make(start: .make(year: 2022, month: 2, day: 2), title: "Find outside trailing margin", calendar: calendar),
        ]

        viewModel.eventListObservable
            .bind { [weak self] in
                self?.eventList = $0
            }
            .disposed(by: disposeBag)

        scheduler.advance(.seconds(1))
    }

    @Test func testSearch_returnsMatchesFromFocusedYearAndFetchMargins() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        searchSubject.onNext("Find")

        #expect(eventList?.date == .distantPast)
        #expect(eventList?.events.map(\.title) == [
            "Find leading margin",
            "Find first day",
            "Find middle of year",
            "Find last day",
            "Find trailing margin",
        ])
    }

    @Test func testSearch_limitsResultsToTwelveEvents() {

        let calendar = CalendarModel.make(id: "calendar", account: "Account", title: "Calendar", color: .blue)
        calendarService.m_events = (1...13).map {
            .make(
                start: .make(year: 2021, month: $0, day: 1),
                title: "Find \($0)",
                calendar: calendar
            )
        }

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        searchSubject.onNext("Find")

        #expect(eventList?.events.map(\.title) == (2...13).map { "Find \($0)" })
    }

    @Test func testSearch_resultsAreUnaffectedByDateAndHoverChanges() throws {

        var calls = 0

        viewModel.eventListObservable
            .void()
            .bind { calls += 1 }
            .disposed(by: disposeBag)

        #expect(calls == 0)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        searchSubject.onNext("Find")

        #expect(calls == 2)

        let searchResults = try #require(eventList)

        #expect(searchResults.events.count == 5)

        dateSubject.onNext(.make(year: 2021, month: 6, day: 1))
        hoverSubject.onNext(.make(year: 2021, month: 6, day: 15))
        hoverSubject.onNext(nil)

        #expect(eventList == searchResults)
        #expect(calls == 2)
    }
}
