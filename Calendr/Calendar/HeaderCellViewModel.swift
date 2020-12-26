//
//  HeaderCellViewModel.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

struct HeaderCellViewModel {
    private static let formatter = DateFormatter()

    let day: Int
}

extension HeaderCellViewModel {
    var text: String {
        Self.formatter.veryShortWeekdaySymbols[day]
    }
}

