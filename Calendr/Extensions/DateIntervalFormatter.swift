//
//  DateIntervalFormatter.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Foundation

class DateIntervalFormatter: Foundation.DateIntervalFormatter {

    override func string(from fromDate: Date, to toDate: Date) -> String {

        var output = super.string(from: fromDate, to: toDate)

        // 🔨 Fix these separators nonsense so we can normally type them in unit tests
        output = output
            .replacingOccurrences(of: "\u{2009}", with: " ") // thin space -> space
            .replacingOccurrences(of: "\u{2013}", with: "-") // en dash -> hyphen

        // 🔨 Fix another nonsense which shows things like ├week of month: X┤ and (quarter: X)... wtf?! 🤦🏻‍♂️
        output = output
            .replacingOccurrences(of: "├[^:]+: ([^┤]+)┤", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\([^:]+: ([^)]+)\)"#, with: "$1", options: .regularExpression)

        return output
    }
}
