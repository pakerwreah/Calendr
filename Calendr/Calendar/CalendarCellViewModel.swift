//
//  CalendarCellViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

struct DateEvents: Equatable {
    let date: Date
    let events: [EventModel]
}

struct CalendarCellViewModel: Equatable {
    let date: Date
    let inMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isHovered: Bool
    let events: [EventModel]
    let dotsStyle: EventDotsStyle
    let calendar: Calendar
    let showLunarCalendar: Bool
    let showMainlandHolidays: Bool
    let showSolarTerms: Bool
}

extension CalendarCellViewModel {

    var text: String {
        "\(calendar.component(.day, from: date))"
    }

    var lunarDate: ChineseLunarDate? {
        guard showLunarCalendar else { return nil }
        return chineseLunarDate(from: date, calendar: calendar)
    }

    var usesSecondaryLine: Bool { showLunarCalendar || showMainlandHolidays || showSolarTerms }

    var holidayName: String? {
        guard showMainlandHolidays else { return nil }
        return chineseMainlandHolidayName(from: events, date: date, calendar: calendar)
    }

    var solarTermText: String? {
        guard showSolarTerms else { return nil }
        return solarTermName(on: date, calendar: calendar)
    }

    var isSolarTermDay: Bool { holidayName == nil && solarTermText != nil }

    var lunarText: String? { holidayName ?? solarTermText ?? lunarDate?.text }

    var isLunarMonthStart: Bool { holidayName != nil || lunarDate?.isMonthStart == true }

    var isStatutoryRestDay: Bool {
        guard showMainlandHolidays else { return false }
        return isChineseMainlandRestDay(from: events, date: date, calendar: calendar)
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

        let events = events
            .filter {
                calendar.isDate($0.start, lessThanOrEqualTo: date, granularity: .day)
                && $0.type != .reminder(completed: true)
            }

        guard !events.isEmpty else { return [.clear] }

        switch dotsStyle {
            case .none: return [.clear]
            case .single_neutral: return [EventDotsStyle.netralColor]
            case .single_highlighted: return [EventDotsStyle.highlightColor]
            case .multiple: break
        }

        let colors = events
            .map(\.calendar)
            .sorted {
                ($0.account.title.localizedLowercase, $0.title.localizedLowercase)
                <
                ($1.account.title.localizedLowercase, $1.title.localizedLowercase)
            }
            .map(\.color)

        return NSOrderedSet(array: colors).array as! [NSColor]
    }

    static var maximumDotsCount: Int { 3 }
}
