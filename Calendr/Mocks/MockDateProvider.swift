//
//  MockDateProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation

class MockDateProvider: DateProviding {

    let calendar: Calendar
    let initial = Date()
    let start: Date

    var now: Date { start.advanced(by: initial.distance(to: Date())) }

    init(
        calendar: Calendar = .gregorian.with(locale: .init(identifier: "en_GB")),
        start: Date = .make(year: 2021, month: 1, day: 1)
    ) {
        self.calendar = calendar
        self.start = start
    }
}

#endif
