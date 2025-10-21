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
    let dotsStyle: EventDotsStyle

    private let calendar: Calendar

    init(
        date: Date,
        inMonth: Bool,
        isToday: Bool,
        isSelected: Bool,
        isHovered: Bool,
        events: [EventModel],
        dotsStyle: EventDotsStyle,
        calendar: Calendar
    ) {
        self.date = date
        self.inMonth = inMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.events = events
        self.dotsStyle = dotsStyle
        self.calendar = calendar
    }
}

extension CalendarCellViewModel {

    var text: String {
        "\(calendar.component(.day, from: date))"
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

        guard !events.isEmpty else { return [.clear] }

        switch dotsStyle {
            case .none: return [.clear]
            case .single_neutral: return [EventDotsStyle.netralColor]
            case .single_highlighted: return [EventDotsStyle.highlightColor]
            case .multiple: break
        }

        let colors = events
            .filter { $0.type != .reminder(completed: true) }
            .map(\.calendar)
            .sorted {
                ($0.account.title.localizedLowercase, $0.title.localizedLowercase)
                <
                ($1.account.title.localizedLowercase, $1.title.localizedLowercase)
            }
            .map(\.color)

        guard !colors.isEmpty else { return [.clear] }

        return NSOrderedSet(array: colors).array as! [NSColor]
    }

    static var maximumDotsCount: Int { 3 }
}
