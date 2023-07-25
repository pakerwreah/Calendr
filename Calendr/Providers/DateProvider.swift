//
//  DateProvider.swift
//  Calendr
//
//  Created by Paker on 12/01/21.
//

import Foundation

protocol DateProviding: AnyObject {
    var calendar: Calendar { get }
    var now: Date { get }
}

class DateProvider: DateProviding {
    let calendar: Calendar
    var now: Date { Date() }

    init(calendar: Calendar) {
        self.calendar = calendar
    }
}
