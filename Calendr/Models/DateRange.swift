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

    private let dateProvider: DateProviding
    private var calendar: Calendar { dateProvider.calendar }
    private var now: Date { dateProvider.now }

    // fix range ending at 00:00 of the next day
    lazy var fixedEnd = end == start ? end : calendar.date(byAdding: .second, value: -1, to: end)!
    lazy var isSingleDay = calendar.isDate(start, inSameDayAs: fixedEnd)
    lazy var isSameMonth = calendar.isDate(start, equalTo: fixedEnd, toGranularity: .month)
    lazy var startsMidnight = calendar.date(start, matchesComponents: .midnightStart)
    lazy var endsMidnight = [.midnightStart, .midnightEnd].contains { calendar.date(end, matchesComponents: $0) }

    // relative to now
    var startsToday: Bool { calendar.isDate(start, inSameDayAs: now) }
    var endsToday: Bool { calendar.isDate(fixedEnd, inSameDayAs: now) }
    var isPast: Bool { calendar.isDate(end, lessThan: now, granularity: .second) }

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
