//
//  ChineseLunarCalendar.swift
//  Calendr
//
//  Created by Paker on 28/08/2026.
//

import Foundation

/// Format a Gregorian date as a Chinese lunar date string.
/// Returns the lunar day in Chinese numerals (初一、初二、etc.) or month name (正月、二月、etc.) on the first day of the lunar month.
/// Leap months are marked with 闰 prefix.
struct ChineseLunarDate {
    let text: String
    let fullText: String
    let isMonthStart: Bool
}

func chineseLunarDate(from date: Date, calendar gregorianCalendar: Calendar) -> ChineseLunarDate? {
    let chineseCalendar = Calendar(identifier: .chinese)

    let components = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)

    guard let month = components.month, let day = components.day else {
        return nil
    }

    let isLeapMonth = components.isLeapMonth ?? false
    let monthName = chineseMonthName(month: month, isLeapMonth: isLeapMonth)
    let dayName = chineseDayName(day: day)

    if day == 1 {
        return ChineseLunarDate(text: monthName, fullText: monthName + dayName, isMonthStart: true)
    }

    return ChineseLunarDate(text: dayName, fullText: monthName + dayName, isMonthStart: false)
}

func chineseLunarDateString(from date: Date, calendar gregorianCalendar: Calendar) -> String? {
    chineseLunarDate(from: date, calendar: gregorianCalendar)?.text
}

func chineseLunarFullDateString(from date: Date, calendar gregorianCalendar: Calendar) -> String? {
    chineseLunarDate(from: date, calendar: gregorianCalendar)?.fullText
}

/// Convert a lunar day number (1-30) to Chinese numerals.
private func chineseDayName(day: Int) -> String {
    switch day {
    case 1: return "初一"
    case 2: return "初二"
    case 3: return "初三"
    case 4: return "初四"
    case 5: return "初五"
    case 6: return "初六"
    case 7: return "初七"
    case 8: return "初八"
    case 9: return "初九"
    case 10: return "初十"
    case 11: return "十一"
    case 12: return "十二"
    case 13: return "十三"
    case 14: return "十四"
    case 15: return "十五"
    case 16: return "十六"
    case 17: return "十七"
    case 18: return "十八"
    case 19: return "十九"
    case 20: return "二十"
    case 21: return "廿一"
    case 22: return "廿二"
    case 23: return "廿三"
    case 24: return "廿四"
    case 25: return "廿五"
    case 26: return "廿六"
    case 27: return "廿七"
    case 28: return "廿八"
    case 29: return "廿九"
    case 30: return "三十"
    default: return ""
    }
}

/// Convert a lunar month number (1-12) to Chinese month name.
private func chineseMonthName(month: Int, isLeapMonth: Bool) -> String {
    let monthNames = ["正月", "二月", "三月", "四月", "五月", "六月",
                      "七月", "八月", "九月", "十月", "冬月", "腊月"]
    
    guard month >= 1 && month <= 12 else {
        return ""
    }
    
    let monthName = monthNames[month - 1]
    return isLeapMonth ? "闰\(monthName)" : monthName
}
