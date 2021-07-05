//
//  MockCalendarServiceProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

struct MockCalendarServiceProvider: CalendarServiceProviding {

    var events: [EventModel] = []

    let changeObservable: Observable<Void> = .empty()

    func events(from start: Date, to end: Date, calendars: [String]) -> Observable<[EventModel]> { .just(events) }

    func calendars() -> Observable<[CalendarModel]> { .empty() }

    func completeReminder(id: String) -> Observable<Void> { .void() }

    func rescheduleReminder(id: String, to: Date) -> Observable<Void> { .void() }

    func requestAccess() { }
}

#endif
