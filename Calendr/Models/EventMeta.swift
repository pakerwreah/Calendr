//
//  EventMeta.swift
//  Calendr
//
//  Created by Paker on 11/04/2021.
//

import Foundation

class EventMeta {

    let event: EventModel
    let dateProvider: DateProviding

    // fix range ending at 00:00 of the next day
    lazy var fixedEnd = dateProvider.calendar.date(byAdding: .second, value: -1, to: event.end)!
    lazy var startsToday = dateProvider.calendar.isDate(event.start, inSameDayAs: dateProvider.now)
    lazy var endsToday = dateProvider.calendar.isDate(fixedEnd, inSameDayAs: dateProvider.now)
    lazy var isSingleDay = dateProvider.calendar.isDate(event.start, inSameDayAs: fixedEnd)
    lazy var isSameMonth = dateProvider.calendar.isDate(event.start, equalTo: fixedEnd, toGranularity: .month)
    lazy var startsMidnight = dateProvider.calendar.date(event.start, matchesComponents: .init(hour: 0, minute: 0))
    lazy var endsMidnight = dateProvider.calendar.date(event.end, matchesComponents: .init(hour: 0, minute: 0))
    lazy var isPast = dateProvider.calendar.isDate(event.end, lessThan: dateProvider.now, granularity: .second)

    init(event: EventModel, dateProvider: DateProviding) {
        self.event = event
        self.dateProvider = dateProvider
    }
}
