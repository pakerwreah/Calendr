//
//  Calendar.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import Foundation

extension Calendar {

    func isDate(_ date: Date, in range: (start: Date, end: Date)) -> Bool {

        let (start, end) = range

        if end < start {
            return false
        }

        // date >= start
        let gte = isDate(date, greaterThanOrEqualTo: start, granularity: .day)

        // fix range ending at 00:00 of the next day
        let fixedEnd = start == end ? end : self.date(byAdding: .second, value: -1, to: end)!

        // date <= end
        let lte = isDate(date, lessThanOrEqualTo: fixedEnd, granularity: .day)

        return gte && lte
    }

    func isDate(_ date: Date, lessThan other: Date, granularity: Component = .day) -> Bool {
        compare(date, to: other, toGranularity: granularity) == .orderedAscending
    }

    func isDate(_ date: Date, lessThanOrEqualTo other: Date, granularity: Component = .day) -> Bool {
        compare(date, to: other, toGranularity: granularity) != .orderedDescending
    }

    func isDate(_ date: Date, greaterThan other: Date, granularity: Component = .day) -> Bool {
        compare(date, to: other, toGranularity: granularity) == .orderedDescending
    }

    func isDate(_ date: Date, greaterThanOrEqualTo other: Date, granularity: Component = .day) -> Bool {
        compare(date, to: other, toGranularity: granularity) != .orderedAscending
    }

    func endOfDay(for date: Date) -> Date {
        startOfDay(for: self.date(byAdding: .day, value: 1, to: date)!)
    }
}
