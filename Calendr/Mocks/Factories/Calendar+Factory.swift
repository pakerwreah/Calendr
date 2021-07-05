//
//  Calendar+Factory.swift
//  Calendr
//
//  Created by Paker on 06/07/2021.
//

#if DEBUG

import Foundation

extension Calendar {

    static let gregorian = Calendar(identifier: .gregorian)

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
