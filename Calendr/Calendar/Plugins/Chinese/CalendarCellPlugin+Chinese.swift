//
//  CalendarCellPlugin+Chinese.swift
//  Calendr
//
//  Created by Paker on 29/08/2026.
//

import AppKit

struct ChineseCalendarCellPlugin: CalendarCellPlugin {
    let text: String?
    let textColor: NSColor?
    let font: NSFont?
    let spacing: CGFloat? = 1

    init(for date: Date) {

        let lunarDate = ChineseLunarDate(from: date)
        let solarTerm = ChineseSolarTerm(from: date)

        let isMonthStart = lunarDate?.isMonthStart == true

        text = solarTerm?.text ?? lunarDate?.text

        textColor = solarTerm != nil
        ? .systemBrown.withAlphaComponent(0.85)
        : isMonthStart
        ? .labelColor
        : .secondaryLabelColor

        font = .systemFont(
            ofSize: 9,
            weight: isMonthStart ? .semibold : .regular
        )
    }

    static let cellSize: CGSize = .init(width: 30, height: 38)
}
