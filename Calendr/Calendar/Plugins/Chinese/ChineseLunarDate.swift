//
//  ChineseLunarDate.swift
//  Calendr
//
//  Created by Paker on 29/08/2026.
//  Authored by Boni (imboni)
//

import Foundation

private let chineseCalendar = Calendar(identifier: .chinese)

/// Format a Gregorian date as a Chinese lunar date string.
/// Returns the lunar day in Chinese numerals (初一、初二、etc.) or month name (正月、二月、etc.) on the first day of the lunar month.
/// Leap months are marked with 闰 prefix.
struct ChineseLunarDate: Equatable {
    let text: String
    let fullText: String
    let isMonthStart: Bool
}

extension ChineseLunarDate {

    init?(from date: Date) {
        let components = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)

        guard let month = components.month, let day = components.day else {
            return nil
        }

        let isLeapMonth = components.isLeapMonth ?? false
        let monthName = chineseMonthName(month: month, isLeapMonth: isLeapMonth)
        let dayName = chineseDayName(day: day)

        self.fullText = monthName + dayName

        if day == 1 {
            self.text = monthName
            self.isMonthStart = true
        } else {
            self.text = dayName
            self.isMonthStart = false
        }
    }
}

private let monthNames = [
    "正月", "二月", "三月", "四月", "五月", "六月",
    "七月", "八月", "九月", "十月", "冬月", "腊月"
]

private let dayNames = [
    "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
    "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
]

/// Convert a lunar day number (1-30) to Chinese numerals.
private func chineseDayName(day: Int) -> String {
    dayNames[day - 1]
}

/// Convert a lunar month number (1-12) to Chinese month name.
private func chineseMonthName(month: Int, isLeapMonth: Bool) -> String {
    let monthName = monthNames[month - 1]
    return isLeapMonth ? "闰\(monthName)" : monthName
}
