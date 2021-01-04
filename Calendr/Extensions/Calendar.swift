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
        let gte = compare(date, to: start, toGranularity: .day) != .orderedAscending

        // fix range ending at 00:00 of the next day
        let fixedEnd = start == end ? end : self.date(byAdding: .second, value: -1, to: end)!

        // date <= end
        let lte = compare(date, to: fixedEnd, toGranularity: .day) != .orderedDescending

        return gte && lte
    }
}
