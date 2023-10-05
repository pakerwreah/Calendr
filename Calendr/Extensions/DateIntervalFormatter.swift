//
//  DateIntervalFormatter.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Foundation

class DateIntervalFormatter: Foundation.DateIntervalFormatter {

    override var calendar: Calendar! {
        didSet {
            locale = calendar.locale
            timeZone = calendar.timeZone
        }
    }

    // 🔨 Fix this fucking nonsense so we can normally type them in unit tests
    override func string(from fromDate: Date, to toDate: Date) -> String {
        super.string(from: fromDate, to: toDate)
            .replacingOccurrences(of: "\u{2009}", with: " ") // thin space
            .replacingOccurrences(of: "\u{00A0}", with: " ") // no-break space
            .replacingOccurrences(of: "\u{202F}", with: " ") // narrow no-break space
            .replacingOccurrences(of: "\u{2013}", with: "-") // en dash
    }
}
