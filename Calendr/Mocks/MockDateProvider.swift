//
//  MockDateProvider.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation

struct MockDateProvider: DateProviding {

    var calendar: Calendar = .gregorian.with(locale: .init(identifier: "en_GB"))

    let initial = Date()
    var start: Date = .make(year: 2021, month: 1, day: 1)
    var now: Date { start.advanced(by: initial.distance(to: Date())) }
}

#endif
