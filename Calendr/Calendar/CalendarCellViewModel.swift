//
//  CalendarCellViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

struct CalendarCellViewModel {
    let label: String
    let inMonth: Bool
    let isWeekend: Bool
    let events: [Event]
}

extension CalendarCellViewModel {
    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var backgroundColor: NSColor {
        isWeekend ? NSColor.gray.withAlphaComponent(0.2) : .clear
    }
}
