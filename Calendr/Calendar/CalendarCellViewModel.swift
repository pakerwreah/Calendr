//
//  CalendarCellViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

struct CalendarCellViewModel {
    let day: Int
    let inMonth: Bool
    let isWeekend: Bool
    let isCurrent: Bool
    let isSelected: Bool
    let events: [Event]
}

extension CalendarCellViewModel {
    var text: String {
        "\(day)"
    }

    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var backgroundColor: NSColor {
        isWeekend ? NSColor.gray.withAlphaComponent(0.2) : .clear
    }
}
