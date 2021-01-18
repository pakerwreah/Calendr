//
//  CalendarViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 09/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class CalendarViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()
    let dateSubject = PublishSubject<Date>()
    let hoverSubject = PublishSubject<Date?>()

    let calendarService = MockCalendarServiceProvider()
    let dateProvider = MockDateProvider()

    lazy var viewModel = CalendarViewModel(
        dateObservable: dateSubject,
        hoverObservable: hoverSubject,
        calendarService: calendarService,
        enabledCalendars: .just([]),
        dateProvider: dateProvider
    )

    var lastValue: [CalendarCellViewModel]?

    override func setUp() {
        viewModel
            .asObservable()
            .bind { [weak self] in
                self?.lastValue = $0
            }
            .disposed(by: disposeBag)

        dateSubject.onNext(dateProvider.today)
    }

    func testDateSpan() {

        guard let cellViewModels = lastValue else {
            return XCTFail()
        }

        XCTAssertEqual(cellViewModels.count, 42)
        XCTAssertEqual(cellViewModels.first.map(\.date), .make(year: 2020, month: 12, day: 27))
        XCTAssertEqual(cellViewModels.last.map(\.date), .make(year: 2021, month: 2, day: 6))
    }

    func testHoverDistinctly() {

        (1...5).map {
            Date.make(year: 2021, month: 1, day: $0)
        }
        .forEach { date in
            hoverSubject.onNext(date)

            guard let hovered = lastValue?.filter(\.isHovered) else {
                return XCTFail()
            }

            XCTAssertEqual(hovered.count, 1)
            XCTAssertEqual(hovered.first.map(\.date), date)
        }
    }

    func testUnhover() {

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        XCTAssertTrue(hasHoveredDate)

        hoverSubject.onNext(nil)
        XCTAssertFalse(hasHoveredDate)
    }

    func testUnhoverAfterMonthChange() {

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        XCTAssertTrue(hasHoveredDate)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        XCTAssertTrue(hasHoveredDate)

        dateSubject.onNext(.make(year: 2021, month: 2, day: 2))
        XCTAssertFalse(hasHoveredDate)
    }

    var hasHoveredDate: Bool {
        lastValue?.filter(\.isHovered).isEmpty == false
    }

    func testSelectDateDistinctly() {

        (1...5).map {
            Date.make(year: 2021, month: 1, day: $0)
        }
        .forEach { date in
            dateSubject.onNext(date)

            guard let selected = lastValue?.filter(\.isSelected) else {
                return XCTFail()
            }

            XCTAssertEqual(selected.count, 1)
            XCTAssertEqual(selected.first.map(\.date), date)
        }
    }

    func testTodayVisibility() {

        dateProvider.today = .make(year: 2020, month: 12, day: 31)

        let expectedPositions: [(date: Date, position: Int?)] = [
            (.make(year: 2020, month: 12, day: 1), 32),
            (.make(year: 2021, month: 1, day: 1), 4),
            (.make(year: 2021, month: 2, day: 1), nil)
        ]

        for (date, position) in expectedPositions {
            dateSubject.onNext(date)

            XCTAssertEqual(lastValue?.map(\.date).lastIndex(of: dateProvider.today), position, "\(date)")
        }
    }

    func testTodayChange() {

        let dates: [Date] = [
            .make(year: 2021, month: 1, day: 1),
            .make(year: 2021, month: 1, day: 2),
            .make(year: 2021, month: 2, day: 1)
        ]

        for date in dates {
            dateProvider.today = date
            dateSubject.onNext(date)

            XCTAssertEqual(lastValue?.first(where: \.isToday).map(\.date), date, "\(date)")
        }
    }

    func testTimezoneChange() {

        dateProvider.m_calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!

        dateProvider.today = .make(year: 2021, month: 1, day: 1, hour: 23)
        dateSubject.onNext(dateProvider.today)

        XCTAssertEqual(lastValue?.firstIndex(where: \.isToday), 5)

        dateProvider.m_calendar.timeZone = TimeZone(identifier: "UTC")!

        dateSubject.onNext(dateProvider.today)

        XCTAssertEqual(lastValue?.firstIndex(where: \.isToday), 6)
    }

    func testEventsPerDate() {

        let expectedEvents: [(date: Date, events: [String])] = [
            (.make(year: 2021, month: 1, day: 1), ["Event 1"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4"]),
        ]

        for (date, expected) in expectedEvents {
            let events = lastValue?
                .first(where: { $0.date == date })
                .map(\.events)?
                .map(\.title)

            XCTAssertEqual(events, expected, "\(date)")
        }
    }

    func testEventDotsPerDate() {

        let expectedEvents: [(date: Date, events: Set<CGColor>)] = [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .clear]),
        ]

        for (date, expected) in expectedEvents {
            let events = lastValue?
                .first(where: { $0.date == date })
                .map(\.dots)

            XCTAssertEqual(events?.count, expected.count, "\(date)")
            XCTAssertEqual(events.map(Set.init), expected, "\(date)")
        }
    }

}

class MockCalendarServiceProvider: CalendarServiceProviding {
    let authObservable: Observable<Void> = .empty()
    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

    var m_calendars: [CalendarModel]
    var m_events: [EventModel]

    init() {
        m_calendars = [
            .init(identifier: "1", account: "A1", title: "Calendar 1", color: .white),
            .init(identifier: "2", account: "A2", title: "Calendar 2", color: .black),
            .init(identifier: "3", account: "A3", title: "Calendar 3", color: .clear)
        ]

        m_events = [
            .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 4),
                isAllDay: true,
                title: "Event 1",
                calendar: m_calendars[0]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 2),
                end: .make(year: 2021, month: 1, day: 2),
                isAllDay: true,
                title: "Event 2",
                calendar: m_calendars[0]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 2, hour: 8),
                end: .make(year: 2021, month: 1, day: 2, hour: 9),
                isAllDay: false,
                title: "Event 3",
                calendar: m_calendars[1]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 3, hour: 14),
                end: .make(year: 2021, month: 1, day: 3, hour: 15),
                isAllDay: false,
                title: "Event 4",
                calendar: m_calendars[2]
            )
        ]
    }

    func calendars() -> [CalendarModel] {
        return m_calendars
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> [EventModel] {
        return m_events
    }
}

class MockDateProvider: DateProviding {
    var m_calendar = Calendar.current
    var calendar: Calendar { m_calendar }
    var today: Date = .make(year: 2021, month: 1, day: 1)
}
