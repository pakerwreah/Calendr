//
//  DateRange.swift
//  Calendr
//
//  Created by Paker on 11/04/2021.
//

import Foundation

class DateRange {

    let start: Date
    let end: Date
    let dateProvider: DateProviding

    // fix range ending at 00:00 of the next day
    lazy var fixedEnd = end == start ? end : dateProvider.calendar.date(byAdding: .second, value: -1, to: end)!
    lazy var startsToday = dateProvider.calendar.isDate(start, inSameDayAs: dateProvider.now)
    lazy var endsToday = dateProvider.calendar.isDate(fixedEnd, inSameDayAs: dateProvider.now)
    lazy var isSingleDay = dateProvider.calendar.isDate(start, inSameDayAs: fixedEnd)
    lazy var isSameMonth = dateProvider.calendar.isDate(start, equalTo: fixedEnd, toGranularity: .month)
    lazy var startsMidnight = dateProvider.calendar.date(start, matchesComponents: .midnightStart)
    lazy var endsMidnight = [.midnightStart, .midnightEnd].contains { dateProvider.calendar.date(end, matchesComponents: $0) }
    lazy var isPast = dateProvider.calendar.isDate(end, lessThan: dateProvider.now, granularity: .second)

    init(start: Date, end: Date, dateProvider: DateProviding) {
        self.start = start
        self.end = end
        self.dateProvider = dateProvider
    }
}

private extension DateComponents {
    static let midnightStart: Self = .init(hour: 0, minute: 0)
    static let midnightEnd: Self = .init(hour: 23, minute: 59)
}
