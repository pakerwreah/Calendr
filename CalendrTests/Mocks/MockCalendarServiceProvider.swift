//
//  MockCalendarServiceProvider.swift
//  CalendrTests
//
//  Created by Paker on 11/03/2021.
//

import Foundation
import RxSwift
@testable import Calendr

typealias CreateReminderArgs = (title: String, date: Date)
typealias EventsArgs = (start: Date, end: Date, calendars: [String])

class MockCalendarServiceProvider: CalendarServiceProviding {

    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

    let (spyEventsObservable, spyEventsObserver) = PublishSubject<EventsArgs>.pipe()
    let (spyCreateReminderObservable, spyCreateReminderObserver) = PublishSubject<CreateReminderArgs>.pipe()
    let (spyCompleteReminderObservable, spyCompleteReminderObserver) = PublishSubject<Bool>.pipe()
    let (spyRescheduleReminderObservable, spyRescheduleReminderObserver) = PublishSubject<Date>.pipe()
    let (spyChangeEventStatusObservable, spyChangeEventStatusObserver) = PublishSubject<EventStatus>.pipe()

    var didRequestAccess: (() -> Void)?

    var m_calendars: [CalendarModel] = []
    var m_events: [EventModel] = []

    func requestAccess() { didRequestAccess?() }

    func calendars() -> Single<[CalendarModel]> { .just(m_calendars) }

    func events(from start: Date, to end: Date, calendars: [String]) -> Single<[EventModel]> {
        spyEventsObserver.onNext((start, end, calendars))
        return .just(m_events)
    }

    func completeReminder(id: String, complete: Bool) -> Completable {
        spyCompleteReminderObserver.onNext(complete)
        return .empty()
    }

    func rescheduleReminder(id: String, to date: Date) -> Completable {
        spyRescheduleReminderObserver.onNext(date)
        return .empty()
    }

    func changeEventStatus(id: String, date: Date, to status: EventStatus) -> Completable {
        spyChangeEventStatusObserver.onNext(status)
        return .empty()
    }

    func createReminder(title: String, date: Date) -> Completable {
        spyCreateReminderObserver.onNext((title, date))
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
