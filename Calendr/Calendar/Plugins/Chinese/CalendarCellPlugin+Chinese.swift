//
//  CalendarCellPlugin+Chinese.swift
//  Calendr
//
//  Created by Paker on 29/08/2026.
//

import AppKit

struct ChineseCalendarCellPlugin: CalendarCellPlugin {
    private(set) var text: String?
    private(set) var textColor: NSColor?
    private(set) var font: NSFont?

    let replaceHoliday = true
    let spacing: CGFloat? = 1

    init(for date: Date, isHoliday: Bool, events: [String]) {

        guard let lunarDate = ChineseLunarDate(from: date) else { return }

        font = .systemFont(
            ofSize: Contants.fontSize,
            weight: lunarDate.isMonthStart ? .semibold : .regular
        )

        if isHoliday, let holiday = events.firstNonNil(ChineseHoliday.init) {
            text = holiday.text
            textColor = .systemRed
        }
        else if let solarTerm = ChineseSolarTerm(from: date) {
            text = solarTerm.text
            textColor = .systemBrown.withAlphaComponent(0.85)
        }
        else {
            text = lunarDate.text
            textColor = .secondaryLabelColor
        }
    }

    static let cellSize: CGSize = .init(width: 30, height: 38)
}

private enum Contants {

    static let fontSize: CGFloat = 9
}
