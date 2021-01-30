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
    let events: [EventModel]?
}

extension CalendarCellViewModel {
    var text: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var borderColor: CGColor {
        let color: NSColor

        if isToday {
            color = .controlAccentColor
        } else if isSelected {
            color = .lightGray
        } else if isHovered {
            color = .placeholderTextColor
        } else {
            color = .clear
        }

        return color.cgColor
    }

    var dots: [CGColor]? {
        guard let events = events else { return nil }

        return Set(events.map(\.calendar.color)).sorted {
            $0.hashValue < $1.hashValue
        }
    }
}
