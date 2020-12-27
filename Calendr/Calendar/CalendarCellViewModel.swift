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
    let isToday: Bool
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

    var borderColor: NSColor {
        if isSelected {
            return .controlAccentColor
        } else if isToday {
            return .gray
        }
        return .clear
    }
}
