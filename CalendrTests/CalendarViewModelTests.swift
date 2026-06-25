//
//  CalendarViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 09/01/21.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class CalendarViewModelTests {

    let disposeBag = DisposeBag()

    let searchSubject = BehaviorSubject<String>(value: "")
    let dateSubject = PublishSubject<Date>()
    let hoverSubject = PublishSubject<Date?>()
    let keyboardModifiers = BehaviorSubject<NSEvent.ModifierFlags>(value: [])
    let calendarsSubject = PublishSubject<[String]>()

    let calendarService = MockCalendarServiceProvider()
    let settings = MockCalendarSettings()
    let dateProvider = MockDateProvider()

    let scheduler = HistoricalScheduler()

    lazy var viewModel = CalendarViewModel(
        searchObservable: searchSubject,
        dateObservable: dateSubject,
        hoverObservable: hoverSubject,
        keyboardModifiers: keyboardModifiers,
        enabledCalendars: calendarsSubject,
        calendarService: calendarService,
        dateProvider: dateProvider,
        settings: settings,
        scheduler: scheduler
    )

    var lastValue: [CalendarCellViewModel]?

    init() {

        calendarService.m_calendars = [
            .make(id: "1", account: "A1", title: "Calendar 1", color: .white),
            .make(id: "2", account: "A2", title: "Calendar 2", color: .black),
            .make(id: "3", account: "A3", title: "Calendar 3", color: .blue),
            .make(id: "4", account: "A4", title: "Reminders", color: .yellow),
        ]

        calendarService.m_events = [
            .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 4),
                title: "Event 1",
                isAllDay: true,
                type: .event(.accepted),
                calendar: calendarService.m_calendars[0]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 2),
                end: .make(year: 2021, month: 1, day: 2),
                title: "Event 2",
                isAllDay: true,
                type: .event(.maybe),
                calendar: calendarService.m_calendars[0]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 2, hour: 8),
                end: .make(year: 2021, month: 1, day: 2, hour: 9),
                title: "Event 3",
                type: .event(.pending),
                calendar: calendarService.m_calendars[1]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 3, hour: 14),
                end: .make(year: 2021, month: 1, day: 3, hour: 15),
                title: "Event 4",
                type: .event(.unknown),
                calendar: calendarService.m_calendars[2]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 3, hour: 15),
                end: .make(year: 2021, month: 1, day: 3, hour: 16),
                title: "Event 5",
                type: .event(.declined),
                calendar: calendarService.m_calendars[2]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 4, hour: 10),
                end: .make(year: 2021, month: 1, day: 4, hour: 11),
                title: "Event 6",
                type: .event(.declined),
                calendar: calendarService.m_calendars[2]
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 5),
                title: "Completed",
                type: .reminder(completed: true),
                calendar: calendarService.m_calendars[3],
            )
        ]

        viewModel
            .cellViewModelsObservable
            .bind { [weak self] in
                self?.lastValue = $0
            }
            .disposed(by: disposeBag)

        calendarsSubject.onNext([])

        settings.toggleWeekNumbers.onNext(true)

        scheduler.advance(.seconds(1))
    }

    @Test func testCombinedTextScaling() {

        var textScaling: CGFloat?

        viewModel.textScaling.bind {
            textScaling = $0
        }
        .disposed(by: disposeBag)

        #expect(textScaling == 1)

        settings.calendarScalingObserver.onNext(2)
        #expect(textScaling == 2)

        settings.calendarTextScalingObserver.onNext(3)
        #expect(textScaling == 6)
    }

    @Test func testCombinedTextScaling_withGlobalTextScalingChange_shouldNotUpdate() {

        var textScaling: CGFloat?

        viewModel.textScaling.bind {
            textScaling = $0
        }
        .disposed(by: disposeBag)

        #expect(textScaling == 1)

        settings.textScalingObserver.onNext(2)

        #expect(textScaling == 1)
    }

    @Test func testTitle() {

        var titles: [String] = []

        viewModel.title.bind {
            titles.append($0)
        }
        .disposed(by: disposeBag)

        dateProvider.m_calendar.locale = Locale(identifier: "fr")
        dateProvider.notifyCalendarUpdated()

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        dateSubject.onNext(.make(year: 2021, month: 2, day: 1))

        #expect(titles == ["Janv. 2021", "Févr. 2021"])
    }

    @Test func testMonthSpan() throws {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        let cellViewModels = try #require(lastValue)

        let inMonth = cellViewModels.filter(\.inMonth)

        #expect(inMonth.count == 31)
        #expect(inMonth.first.map(\.date) == .make(year: 2021, month: 1, day: 1))
        #expect(inMonth.last.map(\.date) == .make(year: 2021, month: 1, day: 31))
    }

    @Test func testDateSpan_weekCount7() throws {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        settings.weekCountObserver.onNext(7)
        scheduler.advance(.milliseconds(300))

        let cellViewModels = try #require(lastValue)

        #expect(cellViewModels.count == 49)
        #expect(cellViewModels.first.map(\.date) == .make(year: 2020, month: 12, day: 27))
        #expect(cellViewModels.last.map(\.date) == .make(year: 2021, month: 2, day: 13))
    }

    @Test func testDateSpan_firstWeekDaySunday() throws {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        let cellViewModels = try #require(lastValue)

        #expect(cellViewModels.count == 42)
        #expect(cellViewModels.first.map(\.date) == .make(year: 2020, month: 12, day: 27))
        #expect(cellViewModels.last.map(\.date) == .make(year: 2021, month: 2, day: 6))
    }

    @Test func testDateSpan_firstWeekDayMonday() throws {

        dateProvider.m_calendar.firstWeekday = 2
        dateProvider.notifyCalendarUpdated()

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        let cellViewModels = try #require(lastValue)

        #expect(cellViewModels.count == 42)
        #expect(cellViewModels.first.map(\.date) == .make(year: 2020, month: 12, day: 28))
        #expect(cellViewModels.last.map(\.date) == .make(year: 2021, month: 2, day: 7))
    }

    @Test func testDateSpan_firstWeekDayGreaterThanMonthStart() throws {

        dateProvider.m_calendar.firstWeekday = 2
        dateProvider.notifyCalendarUpdated()

        dateSubject.onNext(.make(year: 2021, month: 8, day: 1))

        let cellViewModels = try #require(lastValue)

        #expect(cellViewModels.count == 42)
        #expect(cellViewModels.first.map(\.date) == .make(year: 2021, month: 7, day: 26))
        #expect(cellViewModels.last.map(\.date) == .make(year: 2021, month: 9, day: 5))
    }

    @Test func testWeekDays_firstWeekDaySunday() {

        var weekDays: [WeekDay]?

        viewModel.weekDays
            .bind { weekDays = $0 }
            .disposed(by: disposeBag)

        let expected = ["S", "M", "T", "W", "T", "F", "S"]

        #expect(weekDays?.map(\.title) == expected)
    }

    @Test func testWeekDays_firstWeekDayMonday() {

        dateProvider.m_calendar.firstWeekday = 2
        dateProvider.notifyCalendarUpdated()

        var weekDays: [WeekDay]?

        viewModel.weekDays
            .bind { weekDays = $0 }
            .disposed(by: disposeBag)

        let expected = ["M", "T", "W", "T", "F", "S", "S"]

        #expect(weekDays?.map(\.title) == expected)
    }

    @Test func testWeekDays_isHighlighted() {

        var weekDays: [WeekDay]?

        viewModel.weekDays
            .bind { weekDays = $0 }
            .disposed(by: disposeBag)

        #expect(weekDays?.filter(\.isHighlighted).map(\.title) == ["S", "S"])

        settings.highlightedWeekdaysObserver.onNext([1, 2, 5])

        #expect(weekDays?.filter(\.isHighlighted).map(\.title) == ["M", "T", "F"])
    }

    @Test func testWeekNumbers_shouldReturnWeekNumbersIfEnabled() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        settings.toggleWeekNumbers.onNext(false)

        var weekNumbers: [Int]?

        viewModel.weekNumbers
            .bind { weekNumbers = $0 }
            .disposed(by: disposeBag)

        #expect(weekNumbers == nil)

        settings.toggleWeekNumbers.onNext(true)

        #expect(weekNumbers != nil)
    }

    @Test func testWeekNumbers_gregorianCalendar() {

        var weekNumbers: [Int]?

        viewModel.weekNumbers
            .bind { weekNumbers = $0 }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        #expect(weekNumbers == Array(1...6))

        dateSubject.onNext(.make(year: 2021, month: 2, day: 1))
        #expect(weekNumbers == Array(6...11))
    }

    @Test func testWeekNumbers_iso8601Calendar_firstWeekDayMonday() {

        dateProvider.m_calendar = .iso8601
        dateProvider.notifyCalendarUpdated()

        var weekNumbers: [Int]?

        viewModel.weekNumbers
            .bind { weekNumbers = $0 }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        #expect(weekNumbers == Array([53, 1, 2, 3, 4, 5]))

        dateSubject.onNext(.make(year: 2021, month: 2, day: 1))
        #expect(weekNumbers == Array(5...10))
    }

    @Test func testHoverDistinctly() throws {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        try (1...5).map {
            Date.make(year: 2021, month: 1, day: $0)
        }
        .forEach { date in
            hoverSubject.onNext(date)

            let hovered = try #require(lastValue).filter(\.isHovered)

            #expect(hovered.count == 1)
            #expect(hovered.first.map(\.date) == date)
        }
    }

    @Test func testUnhover() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        #expect(hasHoveredDate)

        hoverSubject.onNext(nil)
        #expect(hasHoveredDate == false)
    }

    @Test func testUnhoverAfterMonthChange() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        #expect(hasHoveredDate)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        #expect(hasHoveredDate)

        dateSubject.onNext(.make(year: 2021, month: 2, day: 2))
        #expect(hasHoveredDate == false)
    }

    @Test func testHoverWithOption() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        #expect(hasHoveredDate)

        settings.toggleDateHoverOption.onNext(true)
        #expect(hasHoveredDate == false)

        keyboardModifiers.onNext([.command])
        #expect(hasHoveredDate == false)

        keyboardModifiers.onNext([.option])
        #expect(hasHoveredDate)

        keyboardModifiers.onNext([.option, .capsLock])
        #expect(hasHoveredDate)
    }

    var hasHoveredDate: Bool {
        lastValue?.filter(\.isHovered).isEmpty == false
    }

    @Test func testSelectDateDistinctly() throws {

        try (1...5).map {
            Date.make(year: 2021, month: 1, day: $0)
        }
        .forEach { date in
            dateSubject.onNext(date)

            let selected = try #require(lastValue).filter(\.isSelected)

            #expect(selected.count == 1)
            #expect(selected.first.map(\.date) == date)
        }
    }

    @Test func testTodayVisibility() {

        dateProvider.now = .make(year: 2020, month: 12, day: 31)

        let expectedPositions: [(date: Date, position: Int?)] = [
            (.make(year: 2020, month: 12, day: 1), 32),
            (.make(year: 2021, month: 1, day: 1), 4),
            (.make(year: 2021, month: 2, day: 1), nil)
        ]

        for (date, position) in expectedPositions {
            dateSubject.onNext(date)

            #expect(lastValue?.map(\.date).lastIndex(of: dateProvider.now) == position, "\(date)")
        }
    }

    @Test func testTodayChange() {

        let dates: [Date] = [
            .make(year: 2021, month: 1, day: 1),
            .make(year: 2021, month: 1, day: 2),
            .make(year: 2021, month: 2, day: 1)
        ]

        for date in dates {
            dateProvider.now = date
            dateSubject.onNext(date)

            #expect(lastValue?.first(where: \.isToday).map(\.date) == date, "\(date)")
        }
    }

    @Test func testTimeZoneChange() {

        let timeZone = TimeZone(abbreviation: "UTC-1")!

        dateProvider.m_calendar.timeZone = timeZone
        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 23, timeZone: timeZone)

        dateSubject.onNext(dateProvider.now)

        #expect(lastValue?.firstIndex(where: \.isToday) == 5)

        dateProvider.m_calendar.timeZone = .utc

        dateSubject.onNext(dateProvider.now)

        #expect(lastValue?.firstIndex(where: \.isToday) == 6)
    }

    @Test func testEventsPerDate() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4"]),
            (.make(year: 2021, month: 1, day: 4), []),
        ])
    }

    @Test func testEventsPerDate_withAllDayEventsDisabled_shouldNotShowAllDayEvents() {

        settings.toggleAllDayEvents.onNext(false)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), []),
            (.make(year: 2021, month: 1, day: 2), ["Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 4"]),
            (.make(year: 2021, month: 1, day: 4), []),
        ])
    }

    @Test func testEventDotsPerDate_withAllDayEventsDisabled_shouldNotShowAllDayDots() {

        settings.toggleAllDayEvents.onNext(false)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.clear]),
            (.make(year: 2021, month: 1, day: 2), [.black]),
            (.make(year: 2021, month: 1, day: 3), [.blue]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
        ])
    }

    @Test func testEventsPerDate_withDeclinedEvents() {

        settings.toggleDeclinedEvents.onNext(true)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4", "Event 5"]),
            (.make(year: 2021, month: 1, day: 4), ["Event 6"]),
        ])
    }

    @Test func testEventsPerDate_withFutureEvents_shouldOnlyShowFutureEventsInCurrentDate() {

        settings.futureEventsDaysObserver.onNext(1)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4"]),
            (.make(year: 2021, month: 1, day: 4), []),
        ])

        settings.futureEventsDaysObserver.onNext(2)

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1", "Event 2", "Event 3", "Event 4"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4"]),
            (.make(year: 2021, month: 1, day: 4), []),
        ])
    }

    @Test func testEventsPerDate_withFutureEvents_withDeclinedEvents_shouldOnlyShowFutureEventsInCurrentDate() {

        settings.toggleDeclinedEvents.onNext(true)
        settings.futureEventsDaysObserver.onNext(1)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4", "Event 5"]),
            (.make(year: 2021, month: 1, day: 4), ["Event 6"]),
        ])

        settings.futureEventsDaysObserver.onNext(2)

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Event 1", "Event 2", "Event 3", "Event 4", "Event 5"]),
            (.make(year: 2021, month: 1, day: 2), ["Event 1", "Event 2", "Event 3"]),
            (.make(year: 2021, month: 1, day: 3), ["Event 1", "Event 4", "Event 5"]),
            (.make(year: 2021, month: 1, day: 4), ["Event 6"]),
        ])
    }

    @Test func testFutureEventsInSelectedDate_withSelectedDateToday() {

        var events: [EventModel]?

        viewModel
            .focusedDateEventsObservable
            .bind { events = $0.events }
            .disposed(by: disposeBag)

        settings.toggleDeclinedEvents.onNext(true) // just to show more events
        settings.futureEventsDaysObserver.onNext(1)

        dateProvider.now = .make(year: 2021, month: 1, day: 2)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))

        #expect(events?.map(\.title) == ["Event 1", "Event 2", "Event 3", "Event 4", "Event 5"])

        dateProvider.now = .make(year: 2021, month: 1, day: 3)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 3))

        #expect(events?.map(\.title) == ["Event 1", "Event 4", "Event 5", "Event 6"])

        dateProvider.now = .make(year: 2021, month: 1, day: 4)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 4))

        #expect(events?.map(\.title) == ["Event 6", "Completed"])
    }

    @Test func testFutureEventsInSelectedDate_withSelectedDateNotToday() {

        var events: [EventModel]?

        viewModel
            .focusedDateEventsObservable
            .bind { events = $0.events }
            .disposed(by: disposeBag)

        settings.toggleDeclinedEvents.onNext(true) // just to show more events
        settings.futureEventsDaysObserver.onNext(1)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))

        #expect(events?.map(\.title) == ["Event 1", "Event 2", "Event 3"])

        dateSubject.onNext(.make(year: 2021, month: 1, day: 3))

        #expect(events?.map(\.title) == ["Event 1", "Event 4", "Event 5"])

        dateSubject.onNext(.make(year: 2021, month: 1, day: 4))

        #expect(events?.map(\.title) == ["Event 6"])
    }

    @Test func testEventDotsPerDate() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
        ])
    }

    @Test func testEventDotsPerDate_shouldNotShowFutureEvents() {

        settings.futureEventsDaysObserver.onNext(5)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
        ])
    }

    @Test func testEventDotsPerDate_withDeclinedEvents() {

        settings.toggleDeclinedEvents.onNext(true)
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
            (.make(year: 2021, month: 1, day: 4), [.blue]),
        ])
    }

    @Test func testEventDotsPerDate_withPendingReminder() {

        calendarService.m_events.append(
            .make(
                start: .make(year: 2021, month: 1, day: 1),
                title: "Pending",
                type: .reminder(completed: false),
                calendar: .make(id: "X", account: "X", title: "Reminders", color: .red),
            )
        )

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white, .red]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
        ])
    }

    @Test func testEventDotsPerDate_withCompletedReminder() {

        calendarService.m_events.append(
            .make(
                start: .make(year: 2021, month: 1, day: 1),
                title: "Completed",
                type: .reminder(completed: true),
                calendar: .make(id: "X", account: "X", title: "Reminders", color: .red),
            )
        )

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
        ])
    }

    @Test func testEventDotsPerDate_withHiddenItems() {

        calendarService.m_events = [
            .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 1, hour: 11),
                title: "Declined",
                type: .event(.declined),
                calendar: .make(id: "E", account: "X", title: "Events", color: .blue)
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 1),
                title: "Completed 1",
                type: .reminder(completed: true),
                calendar: .make(id: "R", account: "X", title: "Reminders", color: .red),
            ),
            .make(
                start: .make(year: 2021, month: 1, day: 2),
                title: "Completed 2",
                type: .reminder(completed: true),
                calendar: .make(id: "R", account: "X", title: "Reminders", color: .red),
            )
        ]

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        settings.toggleDeclinedEvents.onNext(true)

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Declined", "Completed 1"]),
            (.make(year: 2021, month: 1, day: 2), ["Completed 2"]),
        ])

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.blue]),
            (.make(year: 2021, month: 1, day: 2), [.clear]),
        ])

        settings.toggleDeclinedEvents.onNext(false)

        assertExpectedEvents({ $0.events.map(\.title) }, [
            (.make(year: 2021, month: 1, day: 1), ["Completed 1"]),
            (.make(year: 2021, month: 1, day: 2), ["Completed 2"]),
        ])

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.clear]),
            (.make(year: 2021, month: 1, day: 2), [.clear]),
        ])
    }

    @Test func testEvents_withOverdueReminder_withSelectedDateToday() {

        calendarService.m_events.append(contentsOf: [
            .make(
                start: .make(year: 2020, month: 12, day: 30),
                title: "Overdue 1",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            ),
            .make(
                start: .make(year: 2020, month: 12, day: 31),
                title: "Overdue 2",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            )
        ])

        var events: [EventModel]?

        viewModel
            .focusedDateEventsObservable
            .bind { events = $0.events }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        #expect(events?.map(\.title) == ["Overdue 1", "Overdue 2" ,"Event 1"])
    }

    @Test func testEvents_withOverdueReminder_withSelectedDateNotToday() {

        dateProvider.now = .make(year: 2021, month: 1, day: 2)

        calendarService.m_events.append(contentsOf: [
            .make(
                start: .make(year: 2020, month: 12, day: 30),
                title: "Overdue 1",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            ),
            .make(
                start: .make(year: 2020, month: 12, day: 31),
                title: "Overdue 2",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            )
        ])

        var events: [EventModel]?

        viewModel
            .focusedDateEventsObservable
            .bind { events = $0.events }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        #expect(events?.map(\.title) == ["Event 1"])
    }

    /// Ensure overdues are not affected when future events are enabled.
    ///
    /// This used to be a problem, because the same future event could be shared by multiple cells.
    /// It should be fine now, since future events are only fetched for the current date.
    /// I kept the test because it doesn't hurt to make sure it still works properly.
    @Test func testEvents_withOverdueReminder_withSelectedDateToday_withFutureEvents() {

        settings.futureEventsDaysObserver.onNext(2)

        calendarService.m_events.append(contentsOf: [
            .make(
                start: .make(year: 2020, month: 12, day: 30),
                title: "Overdue 1",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            ),
            .make(
                start: .make(year: 2020, month: 12, day: 31),
                title: "Overdue 2",
                type: .reminder(completed: false),
                calendar: calendarService.m_calendars[0]
            )
        ])

        var events: [EventModel]?

        viewModel
            .focusedDateEventsObservable
            .bind { events = $0.events }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        #expect(events?.map(\.title) == ["Overdue 1", "Overdue 2" ,"Event 1", "Event 2", "Event 3", "Event 4"])
    }

    @Test func testEventDotsPerDate_withSearch() {

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        searchSubject.onNext("3")
        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.clear]),
            (.make(year: 2021, month: 1, day: 2), [.black]),
            (.make(year: 2021, month: 1, day: 3), [.clear])
        ])

        searchSubject.onNext("1")
        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white]),
            (.make(year: 2021, month: 1, day: 3), [.white])
        ])

        searchSubject.onNext("")
        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [.white]),
            (.make(year: 2021, month: 1, day: 2), [.white, .black]),
            (.make(year: 2021, month: 1, day: 3), [.white, .blue]),
        ])
    }

    @Test func testEventDotsPerDate_withNeutralOption() {

        settings.eventDotsStyleObserver.onNext(.single_neutral)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [EventDotsStyle.netralColor]),
            (.make(year: 2021, month: 1, day: 2), [EventDotsStyle.netralColor]),
            (.make(year: 2021, month: 1, day: 3), [EventDotsStyle.netralColor]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
            (.make(year: 2021, month: 1, day: 5), [.clear]),
        ])
    }

    @Test func testEventDotsPerDate_withHighlightedOption() {

        settings.eventDotsStyleObserver.onNext(.single_highlighted)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))

        assertExpectedEvents(\.dots, [
            (.make(year: 2021, month: 1, day: 1), [EventDotsStyle.highlightColor]),
            (.make(year: 2021, month: 1, day: 2), [EventDotsStyle.highlightColor]),
            (.make(year: 2021, month: 1, day: 3), [EventDotsStyle.highlightColor]),
            (.make(year: 2021, month: 1, day: 4), [.clear]),
            (.make(year: 2021, month: 1, day: 5), [.clear]),
        ])
    }

    @Test func testServiceProviderEventsDateRange() {

        var ranges: [[Date]] = []

        calendarService.spyEventsObservable.bind {
            ranges.append([$0.start, $0.end])
        }
        .disposed(by: disposeBag)

        calendarsSubject.onNext(["1"])
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        dateSubject.onNext(.make(year: 2021, month: 2, day: 1))

        #expect(ranges == [
            [.make(year: 2020, month: 12, day: 27), .make(year: 2021, month: 2, day: 6, at: .end)], // calendar
            [.make(year: 2021, month: 1, day: 31), .make(year: 2021, month: 3, day: 13, at: .end)] // month change
        ])
    }

    @Test func testServiceProviderEventsCalendars() {

        var calendars: [[String]] = []

        calendarService.spyEventsObservable.map(\.calendars).bind {
            calendars.append($0)
        }
        .disposed(by: disposeBag)

        calendarsSubject.onNext(["1", "2", "3"])
        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        dateSubject.onNext(.make(year: 2021, month: 2, day: 1))
        calendarsSubject.onNext(["1", "3"])

        #expect(calendars == [
            ["1", "2", "3"], // calendar
            ["1", "2", "3"], // month change
            ["1", "3"] // calendar
        ])
    }

    // MARK: - Helpers

    private func assertExpectedEvents<T, U: Collection<T> & Equatable>(
        _ pick: (CalendarCellViewModel) -> U,
        _ expectedItems: [(Date, U)]
    ) {
        func named<V>(_ value: V) -> String {
            if let color = value as? NSColor {
                color.name
            } else {
                "\(value)"
            }
        }

        for (date, expected) in expectedItems {
            guard let actual = lastValue?.first(where: { $0.date == date }).map(pick) else {
                Issue.record("\(date) not found")
                return
            }
            #expect(actual.map(named) == expected.map(named), "\(date)")
        }
    }
}

private extension NSColor {

    var name: String {
        switch self {
            case .white: ".white"
            case .black: ".black"
            case .clear: ".clear"
            case .red: ".red"
            case .green: ".green"
            case .blue: ".blue"
            default: self.description
        }
    }
}
