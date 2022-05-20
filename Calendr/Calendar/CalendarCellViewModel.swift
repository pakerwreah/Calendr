//
//  CalendarCellViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

struct CalendarCellViewModel: Equatable {
    let date: Date
    let inMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isHovered: Bool
    let events: [EventModel]
}

extension CalendarCellViewModel {
    var text: String {
        "\(Calendar.autoupdatingCurrent.component(.day, from: date))"
    }

    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var borderColor: NSColor {
        if isToday {
            return .controlAccentColor
        } else if isSelected {
            return .secondaryLabelColor
        } else if isHovered {
            return .tertiaryLabelColor
        } else {
            return .clear
        }
    }

    var dots: [NSColor] {
        Set(events.map(\.calendar.color)).sorted(by: \.hashValue)
    }
}
