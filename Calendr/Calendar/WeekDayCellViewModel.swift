//
//  WeekDayCellViewModel.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

struct WeekDayCellViewModel {
    private static let formatter = DateFormatter()

    let day: Int
}

extension WeekDayCellViewModel {
    var text: String {
        Self.formatter.veryShortWeekdaySymbols[day]
    }
}

