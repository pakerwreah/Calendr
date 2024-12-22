//
//  Calendar+Factory.swift
//  Calendr
//
//  Created by Paker on 06/07/2021.
//

import Foundation

extension Calendar {

    func with(timeZone: TimeZone) -> Self {
        var copy = self
        copy.timeZone = timeZone
        return copy
    }
}

#if DEBUG

extension Calendar {

    static let gregorian = Calendar(identifier: .gregorian).with(timeZone: .utc)
    static let iso8601 = Calendar(identifier: .iso8601).with(timeZone: .utc)

    func with(locale: Locale) -> Self {
        var copy = self
        copy.locale = locale
        return copy
    }

    func with(firstWeekday: Int) -> Self {
        var copy = self
        copy.firstWeekday = firstWeekday
        return copy
    }
}

#endif
