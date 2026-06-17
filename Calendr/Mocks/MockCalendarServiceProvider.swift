//
//  MockCalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

typealias RescheduleReminderArgs = (date: Date, isAllDay: Bool)
typealias CreateReminderArgs = (title: String, calendar: String, date: Date, isAllDay: Bool)
typealias CreateEventArgs = (
    title: String,
    calendar: String,
    start: Date,
    end: Date,
    isAllDay: Bool,
    location: String?,
    url: URL?,
    notes: String?,
    alertOffset: TimeInterval?,
    timeZone: TimeZone
)
typealias EventsArgs = (start: Date, end: Date, calendars: [String])

class MockCalendarServiceProvider: CalendarServiceProviding {

    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

    let (spyEventsObservable, spyEventsObserver) = PublishSubject<EventsArgs>.pipe()
    let (spyCreateReminderObservable, spyCreateReminderObserver) = PublishSubject<CreateReminderArgs>.pipe()
    let (spyCreateEventObservable, spyCreateEventObserver) = PublishSubject<CreateEventArgs>.pipe()
    let (spyCompleteReminderObservable, spyCompleteReminderObserver) = PublishSubject<Bool>.pipe()
    let (spyRescheduleReminderObservable, spyRescheduleReminderObserver) = PublishSubject<RescheduleReminderArgs>.pipe()
    let (spyChangeEventStatusObservable, spyChangeEventStatusObserver) = PublishSubject<EventStatus>.pipe()

    var didRequestAccess: (() -> Void)?

    var m_events: [EventModel]
    var m_calendars: [CalendarModel]
    var m_defaultCalendarId: String?
    let dateProvider: DateProviding?

    init(
        events: [EventModel] = [],
        calendars: [CalendarModel] = [],
        dateProvider: DateProviding? = nil
    ) {
        self.m_events = events
        self.m_calendars = calendars
        self.dateProvider = dateProvider
    }

    func requestAccess() {
        didRequestAccess?()
        changeObserver.onNext(())
    }

    func calendars() -> Single<[CalendarModel]> { .just(m_calendars) }

    func calendars(forNew type: CalendarEntityType) -> Single<[CalendarModel]> { .just(m_calendars) }

    func defaultCalendar(forNew type: CalendarEntityType) -> CalendarModel? {
        m_calendars.first { $0.id == m_defaultCalendarId }
    }

    func events(from start: Date, to end: Date, calendars: [String]) -> Single<[EventModel]> {
        spyEventsObserver.onNext((start, end, calendars))

        var events = m_events

        if !calendars.isEmpty {
            events = events.filter { $0.calendar.id.isEmpty || calendars.contains($0.calendar.id) }
        }

        if let dateProvider {
            let calendar = dateProvider.calendar
            events = events.filter {
                calendar.isDay($0.start, inDays: (start, end))
                ||
                calendar.isDay($0.end, inDays: (start, end))
            }
        }

        return .just(events)
    }

    func completeReminder(id: String, complete: Bool) -> Completable {
        spyCompleteReminderObserver.onNext(complete)
        return .empty()
    }

    func rescheduleReminder(id: String, to date: Date, isAllDay: Bool) -> Completable {
        spyRescheduleReminderObserver.onNext((date, isAllDay))
        return .empty()
    }

    func changeEventStatus(id: String, date: Date, to status: EventStatus) -> Completable {
        spyChangeEventStatusObserver.onNext(status)
        return .empty()
    }

    func createReminder(title: String, calendar: String, date: Date, isAllDay: Bool) -> Completable {
        spyCreateReminderObserver.onNext((title, calendar, date, isAllDay))
        return .empty()
    }

    func createEvent(
        title: String,
        calendar: String,
        start: Date,
        end: Date,
        isAllDay: Bool,
        location: String?,
        url: URL?,
        notes: String?,
        alertOffset: TimeInterval?,
        timeZone: TimeZone
    ) -> Completable {
        spyCreateEventObserver.onNext((title, calendar, start, end, isAllDay, location, url, notes, alertOffset, timeZone))
        return .empty()
    }
}

// MARK: - Helpers

extension MockCalendarServiceProvider {

    func changeEvents(_ events: [EventModel]) {
        m_events = events
        changeObserver.onNext(())
    }
}

#endif
