//
//  EventDetailsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 11/04/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class EventDetailsViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    let workspace = MockWorkspaceServiceProvider()
    let settings = MockPopoverSettings()

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(title: "Title", location: "Location", notes: "Notes")
        )

        XCTAssertEqual(viewModel.title, "Title")
        XCTAssertEqual(viewModel.location, "Location")
        XCTAssertEqual(viewModel.notes, "Notes")
    }

    func testDetails_withUrl_isNotBirthday_shouldShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!)
        )

        XCTAssertEqual(viewModel.url, "https://someurl.com")
    }

    func testDetails_withUrl_isBirthday_shouldNotShowURL() {

        let viewModel = mock(
            event: .make(url: URL(string: "https://someurl.com")!, type: .birthday)
        )

        XCTAssertEqual(viewModel.url, "")
    }

    func testDuration_isAllDay_shouldShowOnlyDate() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1),
                end: .make(year: 2021, month: 1, day: 2),
                isAllDay: true
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021")
    }

    func testDuration_isReminder_shouldShowOnlyStart() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                type: .reminder
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 AM")
    }

    func testDuration_isMultiDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2, hour: 20)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 AM - Jan 2, 2021, 8:00 PM")
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 15),
                end: .make(year: 2021, month: 1, day: 1, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 3:00 - 4:00 PM")
    }

    func testDuration_endsMidnight() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2021, month: 1, day: 1, hour: 10),
                end: .make(year: 2021, month: 1, day: 2)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2021, 10:00 - 12:00 AM")
    }

    func testReminder_rescheduleBy1Hour() {

        let viewModel = mock(event: .make(type: .reminder))

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        var date: Date?
        var callback = false

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.reminderActionObserver.onNext(.remind(.init(hour: 1)))

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 1, hour: 13))
        XCTAssert(callback)
    }

    func testReminder_rescheduleTomorrow() {

        let viewModel = mock(event: .make(type: .reminder))

        dateProvider.now = .make(year: 2021, month: 1, day: 1, hour: 12)

        var date: Date?
        var callback = false

        calendarService.spyRescheduleObservable
            .bind { date = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.reminderActionObserver.onNext(.remind(.init(day: 1)))

        XCTAssertEqual(date, .make(year: 2021, month: 1, day: 2, hour: 12))
        XCTAssert(callback)
    }

    func testReminder_markCompleted() {

        let viewModel = mock(event: .make(type: .reminder))

        var complete = false
        var callback = false

        calendarService.spyCompleteObservable
            .bind { complete = true }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.reminderActionObserver.onNext(.complete)

        XCTAssert(complete)
        XCTAssert(callback)
    }

    func testViewModel_isNotReminder_shouldNotCallServiceOrTriggerCallback() {

        let viewModel = mock(event: .make(type: .birthday))

        var reschedule = false
        var complete = false
        var callback = false

        calendarService.spyRescheduleObservable
            .void()
            .bind { reschedule = true }
            .disposed(by: disposeBag)

        calendarService.spyCompleteObservable
            .bind { complete = true }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.reminderActionObserver.onNext(.remind(.init(day: 1)))
        viewModel.reminderActionObserver.onNext(.complete)

        XCTAssertFalse(reschedule)
        XCTAssertFalse(complete)
        XCTAssertFalse(callback)
    }

    func testParticipants_shouldReturnCorrectOrder() {

        let viewModel = mock(
            event: .make(
                participants: [
                    .init(name: "c", status: .unknown, isOrganizer: false, isCurrentUser: false),
                    .init(name: "b", status: .unknown, isOrganizer: false, isCurrentUser: false),
                    .init(name: "me", status: .unknown, isOrganizer: false, isCurrentUser: true),
                    .init(name: "organizer", status: .unknown, isOrganizer: true, isCurrentUser: false),
                    .init(name: "a", status: .unknown, isOrganizer: false, isCurrentUser: false),
                ]
            )
        )

        XCTAssertEqual(viewModel.participants.map(\.name), ["organizer", "me", "a", "b", "c"])
    }

    func testStatusChanged_shouldChangeStatus() {

        let viewModel = mock(event: .make(type: .event(.pending)))

        var status: EventStatus?
        var callback = false

        calendarService.spyChangeEventStatusObservable
            .bind { status = $0 }
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .bind { callback = true }
            .disposed(by: disposeBag)

        viewModel.eventActionObserver.onNext(.accept)

        XCTAssertEqual(status, .accepted)
        XCTAssert(callback)
    }

    func mock(event: EventModel) -> EventDetailsViewModel {

        EventDetailsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            settings: settings,
            isShowingObserver: .dummy(),
            isInProgress: .just(false)
        )
    }
}
