//
//  EventViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 27/01/21.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventViewModelTests {

    let disposeBag = DisposeBag()

    let localStorage = MockLocalStorageProvider()
    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let geocoder = MockGeocodeServiceProvider()
    let weatherService = MockWeatherServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockEventSettings()
    let scheduler = HistoricalScheduler()

    init() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    @Test func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", type: .event(.pending), calendar: .make(color: .black))
        )

        #expect(viewModel.title == "Title")
        #expect(viewModel.color == .black)
        #expect(viewModel.type == .event(.pending))
    }

    @Test func testShowAllDayDetails_isAllDay_withOptionDisabled_shouldNotShowDetails() {

        let viewModel = mock(
            event: .make(isAllDay: true)
        )

        #expect(viewModel.showDetails.lastValue() == true)

        settings.toggleAllDayDetails.onNext(false)

        #expect(viewModel.showDetails.lastValue() == false)
    }

    @Test func testShowAllDayDetails_isNotAllDay_withOptionDisabled_shouldShowDetails() {

        let viewModel = mock(
            event: .make(isAllDay: false)
        )

        #expect(viewModel.showDetails.lastValue() == true)

        settings.toggleAllDayDetails.onNext(false)

        #expect(viewModel.showDetails.lastValue() == true)
    }

    @Test func testSubtitle_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Location https://someurl.com ")
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withExtraSpacesInLocation_withURLInLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " \n https://someurl.com ")
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withEmptyLocation_withURL_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withEmptyLocation_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: " ", notes: " \nSome \nnotes https://someurl.com ")
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withLocation_withoutURL_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address")
        )

        #expect(viewModel.subtitle == "Some address")
    }

    @Test func testSubtitle_withURL_withoutLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withURL_withLocation_shouldShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Some address", url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "Some address")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withURL_withDifferentDomainInLocation_shouldShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Join at someotherurl.com", url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "Join at someotherurl.com")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withURL_withSameDomainInLocation_shouldNotShowLocation_shouldShowURL() {

        let viewModel = mock(
            event: .make(location: "Join at someurl.com", url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withoutLocation_withoutURL_withURLInNotes_shouldShowURL() {

        let viewModel = mock(
            event: .make(notes: "Some notes https://someurl.com")
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withoutLocation_withoutURL_withNotes_shouldShowNotes() {

        let viewModel = mock(
            event: .make(notes: "Some notes")
        )

        #expect(viewModel.subtitle == "Some notes")
    }

    @Test func testSubtitle_withoutLocation_withoutURL_withNotesStartingWithTitle_shouldNotShowNotes() {

        let viewModel = mock(
            event: .make(title: "Title", notes: "Title some notes")
        )

        #expect(viewModel.subtitle == "")
    }

    @Test func testSubtitle_withLocation_isAllDay_shouldShowLocation() {

        let viewModel = mock(
            event: .make(location: "Some address", isAllDay: true)
        )

        #expect(viewModel.subtitle == "Some address")
    }

    @Test func testSubtitle_withURL_isAllDay_isNotBirthday_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == "someurl.com")
    }

    @Test func testSubtitle_withURL_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        #expect(viewModel.subtitle == "")
        #expect(viewModel.subtitleLink == nil)
    }

    @Test func testDuration_isAllDay_isSingleDay_shouldNotShowDuration() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 1),
                isAllDay: true
            )
        )

        #expect(viewModel.duration.lastValue() == "")
    }

    @Test func testDuration_isAllDay_isMultiDay_shouldShowDuration() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2, at: .end),
                isAllDay: true
            )
        )

        #expect(viewModel.duration.lastValue() == "January 1 - 2")
    }

    @Test func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        #expect(viewModel.duration.lastValue() == "3:00 - 4:00 PM")
    }

    @Test func testDuration_endsMidnight() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 2, hour: 0)
            )
        )

        #expect(viewModel.duration.lastValue() == "3:00 PM - 12:00 AM")
    }

    @Test func testDuration_isMultiDay_isSameMonth_withTime() {

        dateProvider.m_calendar = .gregorian.with(timeZone: .utc)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3, hour: 0, minute: 1)
            )
        )

        #expect(viewModel.duration.lastValue() == "2021-01-01 00:00\n2021-01-03 00:01")
    }

    @Test func testDuration_isMultiDay_isDifferentMonth_withTime() {

        dateProvider.m_calendar = .gregorian.with(timeZone: .utc)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3, hour: 0, minute: 1)
            )
        )

        #expect(viewModel.duration.lastValue() == "2021-01-01 00:00\n2021-02-03 00:01")
    }

    @Test func testDuration_isMultiDay_isSameMonth_endsStartOfNextDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 3)
            )
        )

        #expect(viewModel.duration.lastValue() == "January 1 - 2")
    }

    @Test func testDuration_isMultiDay_isDifferentMonth_endsStartOfNextDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 2, day: 3)
            )
        )

        #expect(viewModel.duration.lastValue() == "Jan 1 - Feb 2")
    }

    @Test func testDuration_isSameDay_withDifferentTimeZone() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16),
                timeZone: .init(abbreviation: "GMT-3")
            )
        )

        #expect(viewModel.duration.lastValue() == "12:00 - 1:00 PM (GMT-3)")
    }

    @Test func testDuration_isSameDay_isMeeting_withDifferentTimeZone() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16),
                participants: [.make()],
                timeZone: .init(abbreviation: "GMT-3")
            )
        )

        #expect(viewModel.duration.lastValue() == "3:00 - 4:00 PM")
    }

    @Test func testBarStyle() {

        #expect(mock(type: .birthday).barStyle == .filled)
        #expect(mock(type: .reminder(completed: false)).barStyle == .filled)
        #expect(mock(type: .event(.accepted)).barStyle == .filled)
        #expect(mock(type: .event(.pending)).barStyle == .filled)
        #expect(mock(type: .event(.declined)).barStyle == .filled)
        #expect(mock(type: .event(.maybe)).barStyle == .bordered)
    }

    @Test func testReminderDuration() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 1),
                type: .reminder(completed: false)
            )
        )

        #expect(viewModel.duration.lastValue() == "1:00 AM")
    }

    @Test func testOverdueReminder_shouldShowRelativeDuration() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 0, minute: 30)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 0, minute: 15),
                type: .reminder(completed: false)
            )
        )

        #expect(viewModel.duration.lastValue() == "12:15 AM")
        #expect(viewModel.relativeDuration.lastValue() == "15m ago")
    }

    @Test func testOverdueReminder_isCompleted_shouldNotShowRelativeDuration() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 0, minute: 30)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 0, minute: 15),
                type: .reminder(completed: true)
            )
        )

        #expect(viewModel.duration.lastValue() == "12:15 AM")
        #expect(viewModel.relativeDuration.lastValue() == nil)
    }

    @Test func testOverdueReminder_isAllDay_shouldNotShowDurationOrRelativeDuration() {

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 0, minute: 30)

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                isAllDay: true,
                type: .reminder(completed: false)
            )
        )

        #expect(viewModel.duration.lastValue() == "")
        #expect(viewModel.relativeDuration.lastValue() == nil)
    }

    @Test func testReminder_toggleComplete_isNotCompleted() {

        let viewModel = mock(type: .reminder(completed: false))

        var isCompleted: Bool?
        var serviceCompleted: Bool?

        viewModel.isCompleted
            .bind { isCompleted = $0 }
            .disposed(by: disposeBag)

        calendarService.spyCompleteReminderObservable
            .bind { serviceCompleted = $0 }
            .disposed(by: disposeBag)

        #expect(isCompleted == false)

        viewModel.completeTapped.onNext(())

        #expect(isCompleted == true)
        #expect(serviceCompleted == nil)

        scheduler.advance(.milliseconds(500))

        #expect(isCompleted == true)
        #expect(serviceCompleted == true)
    }

    @Test func testReminder_toggleComplete_isCompleted() {

        let viewModel = mock(type: .reminder(completed: true))

        var isCompleted: Bool?
        var serviceCompleted: Bool?

        viewModel.isCompleted
            .bind { isCompleted = $0 }
            .disposed(by: disposeBag)

        calendarService.spyCompleteReminderObservable
            .bind { serviceCompleted = $0 }
            .disposed(by: disposeBag)

        #expect(isCompleted == true)

        viewModel.completeTapped.onNext(())

        #expect(isCompleted == false)
        #expect(serviceCompleted == nil)

        scheduler.advance(.milliseconds(500))

        #expect(isCompleted == false)
        #expect(serviceCompleted == false)
    }

    @Test func testReminder_toggleComplete_notChanged_shouldNotTriggerService() {

        let viewModel = mock(type: .reminder(completed: false))

        var isCompleted: Bool?
        var serviceCompleted: Bool?

        viewModel.isCompleted
            .bind { isCompleted = $0 }
            .disposed(by: disposeBag)

        calendarService.spyCompleteReminderObservable
            .bind { serviceCompleted = $0 }
            .disposed(by: disposeBag)

        #expect(isCompleted == false)

        viewModel.completeTapped.onNext(())

        #expect(isCompleted == true)
        #expect(serviceCompleted == nil)

        viewModel.completeTapped.onNext(())

        #expect(isCompleted == false)
        #expect(serviceCompleted == nil)

        scheduler.advance(.milliseconds(500))

        #expect(isCompleted == false)
        #expect(serviceCompleted == nil)
    }

    @Test func testRecurrenceIndicator_withNonRecurrentEvent() {

        let viewModel = mock(event: .make(type: .event(.unknown), hasRecurrenceRules: false))

        var showRecurrenceIndicator: Bool?

        viewModel.showRecurrenceIndicator
            .bind { showRecurrenceIndicator = $0 }
            .disposed(by: disposeBag)

        #expect(showRecurrenceIndicator == false)
    }

    @Test func testRecurrenceIndicator_withRecurrentEvent() {

        let viewModel = mock(event: .make(type: .event(.unknown), hasRecurrenceRules: true))

        var showRecurrenceIndicator: Bool?

        viewModel.showRecurrenceIndicator
            .bind { showRecurrenceIndicator = $0 }
            .disposed(by: disposeBag)

        #expect(showRecurrenceIndicator == true)

        settings.toggleRecurrenceIndicator.onNext(false)

        #expect(showRecurrenceIndicator == false)
    }

    @Test func testOpenEventInDefaultCalendar() throws {
        let viewModel = mock(
            event: .make(title: "Title", type: .event(.pending), calendar: .make(color: .black))
        )

        let menu = try #require(viewModel.makeContextMenuViewModel() as? EventOptionsViewModel)
        menu.triggerAction(.open)
    }

    func mock(type: EventType) -> EventViewModel { mock(event: .make(type: type)) }

    func mock(event: EventModel) -> EventViewModel {

        EventViewModel(
            source: .calendar,
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            localStorage: localStorage,
            settings: settings,
            isShowingDetailsModal: .dummy(),
            callback: .dummy(),
            isTodaySelected: true,
            scheduler: scheduler
        )
    }
}
