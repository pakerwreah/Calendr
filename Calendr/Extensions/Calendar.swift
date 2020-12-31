//
//  Calendar.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import Foundation

extension Calendar {
    func isDate(_ date: Date, in range: (start: Date, end: Date), toGranularity component: Calendar.Component) -> Bool {
        // date >= start
        let gte = compare(date, to: range.start, toGranularity: component) != .orderedAscending
        // date <= end
        let lte = compare(date, to: range.end.advanced(by: -1), toGranularity: component) != .orderedDescending

        return gte && lte
    }
}
