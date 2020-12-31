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
    let events: [EventModel]
}

extension CalendarCellViewModel {
    var text: String {
        "\(day)"
    }

    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var borderColor: CGColor {
        if isSelected {
            return NSColor.controlAccentColor.cgColor
        } else if isToday {
            return NSColor.gray.cgColor
        }
        return NSColor.clear.cgColor
    }

    var dots: [CGColor] {
        Set(events.map(\.calendar.color)).sorted {
            $0.hashValue < $1.hashValue
        }
    }
}
