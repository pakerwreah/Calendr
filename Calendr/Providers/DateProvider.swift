//
//  DateProvider.swift
//  Calendr
//
//  Created by Paker on 12/01/21.
//

import Foundation

protocol DateProviding {
    var calendar: Calendar { get }
    var now: Date { get }
}

class DateProvider: DateProviding {
    let calendar: Calendar = .current
    var now: Date { Date() }
}
