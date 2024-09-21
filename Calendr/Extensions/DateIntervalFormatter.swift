//
//  DateIntervalFormatter.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Foundation

class DateIntervalFormatter: Foundation.DateIntervalFormatter, @unchecked Sendable {

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

    override var dateTemplate: String! {
        didSet {
            // https://forums.developer.apple.com/forums/thread/740201
            // it doesn't respect the locale's 12/24h preference
            assert(!dateTemplate.contains("j"), "don't use it! 🐛")
        }
    }
}
