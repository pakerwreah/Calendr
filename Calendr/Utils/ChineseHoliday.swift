//
//  ChineseHoliday.swift
//  Calendr
//

import Foundation

private let statutoryHolidayKeys = ["元旦", "春节", "除夕", "清明", "劳动", "端午", "中秋", "国庆"]
private let festivalHolidayKeys = ["元宵", "七夕", "重阳", "腊八"]
private let solarTermNames = [
    "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
    "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
    "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
    "立冬", "小雪", "大雪", "冬至"
]

private let shanghaiTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 8 * 3600)!

func isChineseMainlandHolidayCalendar(_ calendar: CalendarModel) -> Bool {
    let haystack = calendar.title + " " + calendar.account.title
    if haystack.contains("中国大陆节假日") { return true }
    if haystack.contains("中国节假日") { return true }
    if haystack.localizedCaseInsensitiveContains("Holidays in China") { return true }
    if haystack.localizedCaseInsensitiveContains("China Holidays") { return true }
    if haystack.contains("节假日") && (haystack.contains("中国") || haystack.contains("大陆")) {
        return true
    }
    return false
}

func isMainlandMakeupWorkTitle(_ title: String) -> Bool {
    let text = title.lowercased()
    if title.contains("上班") || title.contains("补班") || title.contains("调休上班") {
        return true
    }
    if text.contains("working day") || text.contains("workday") || text.contains("work day") {
        return true
    }
    return false
}

func isSolarTermName(_ title: String) -> Bool {
    solarTermNames.contains { title.contains($0) } && !title.contains("节")
}

func shortMainlandHolidayName(from title: String) -> String? {
    if isMainlandMakeupWorkTitle(title) { return nil }
    if isSolarTermName(title) { return nil }

    for key in statutoryHolidayKeys + festivalHolidayKeys {
        if title.contains(key) {
            return key
        }
    }

    if title.contains("休息日") || title.contains("放假") {
        return "休息"
    }

    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.count <= 3 { return trimmed }
    return String(trimmed.prefix(2))
}

/// Statutory rest windows. Makeup-work Sundays/Saturdays (e.g. 9/20, 10/10 for 国庆) stay out.
func isStatutoryRestDate(_ key: String, date: Date, calendar: Calendar) -> Bool {
    var shanghaiCalendar = calendar
    shanghaiCalendar.timeZone = shanghaiTimeZone
    let month = shanghaiCalendar.component(.month, from: date)
    let day = shanghaiCalendar.component(.day, from: date)
    switch key {
    case "元旦":
        return month == 1 && (1...3).contains(day)
    case "春节", "除夕":
        return month == 1 || month == 2
    case "清明":
        return month == 4 && (3...7).contains(day)
    case "劳动":
        return month == 5 && (1...5).contains(day)
    case "端午":
        return month == 5 || month == 6
    case "中秋":
        return (month == 9 && day >= 22) || (month == 10 && day <= 8)
    case "国庆":
        return month == 10 && (1...7).contains(day)
    default:
        return true
    }
}

func solarTermName(on date: Date, calendar: Calendar) -> String? {
    var shanghaiCalendar = Calendar(identifier: .gregorian)
    shanghaiCalendar.timeZone = shanghaiTimeZone
    let year = shanghaiCalendar.component(.year, from: date)
    for yearToCheck in [year - 1, year] {
        for index in solarTermNames.indices {
            guard let termDate = dateOfSolarTerm(year: yearToCheck, index: index) else { continue }
            if shanghaiCalendar.isDate(date, inSameDayAs: termDate) {
                return solarTermNames[index]
            }
        }
    }
    return nil
}

func chineseMainlandHolidayName(from events: [EventModel], date: Date, calendar: Calendar) -> String? {
    for event in events where event.isAllDay && isChineseMainlandHolidayCalendar(event.calendar) {
        if isMainlandMakeupWorkTitle(event.title) { continue }
        guard let name = shortMainlandHolidayName(from: event.title) else { continue }

        if statutoryHolidayKeys.contains(name) {
            if isStatutoryRestDate(name, date: date, calendar: calendar) {
                return name
            }
            continue
        }

        // One-day festivals (七夕 etc.): EventKit all-day ends next midnight.
        if calendar.isDate(event.start, inSameDayAs: date) {
            return name
        }
    }
    return nil
}

func isChineseMainlandRestDay(from events: [EventModel], date: Date, calendar: Calendar) -> Bool {
    events.contains { event in
        guard event.isAllDay,
              isChineseMainlandHolidayCalendar(event.calendar),
              !isMainlandMakeupWorkTitle(event.title),
              !isOnlyQingmingSolarTerm(event.title),
              let name = shortMainlandHolidayName(from: event.title),
              statutoryHolidayKeys.contains(name)
        else { return false }
        return isStatutoryRestDate(name, date: date, calendar: calendar)
    }
}

func isSolarTermOverride(from events: [EventModel], date: Date, calendar: Calendar) -> Bool {
    if let name = chineseMainlandHolidayName(from: events, date: date, calendar: calendar) {
        return solarTermNames.contains(name) && !isChineseMainlandRestDay(from: events, date: date, calendar: calendar)
    }
    return false
}

private func isOnlyQingmingSolarTerm(_ title: String) -> Bool {
    title.contains("清明") && !title.contains("节") && !title.contains("放假") && !title.contains("假")
}

private func normalizedDegrees(_ value: Double) -> Double {
    var deg = value.truncatingRemainder(dividingBy: 360)
    if deg < 0 { deg += 360 }
    return deg
}

private func signedAngleDelta(target: Double, actual: Double) -> Double {
    normalizedDegrees(target - actual + 180) - 180
}

private func julianDay(from date: Date) -> Double {
    2440587.5 + date.timeIntervalSince1970 / 86_400
}

/// Apparent geocentric ecliptic longitude of the Sun, Meeus ch. 25 (low accuracy).
private func sunApparentLongitude(julianDay jd: Double) -> Double {
    let T = (jd - 2_451_545.0) / 36_525.0
    let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
    let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
    let Mr = M * .pi / 180
    let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mr)
        + (0.019993 - 0.000101 * T) * sin(2 * Mr)
        + 0.000289 * sin(3 * Mr)
    let omega = 125.04 - 1934.136 * T
    return normalizedDegrees(L0 + C - 0.00569 - 0.00478 * sin(omega * .pi / 180))
}

private func dateOfSolarTerm(year: Int, index: Int) -> Date? {
    guard solarTermNames.indices.contains(index) else { return nil }
    let target = normalizedDegrees(285 + 15 * Double(index))
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0)!
    guard var date = utc.date(from: DateComponents(year: year, month: 1, day: 1, hour: 0)) else {
        return nil
    }
    let dayOfYear = ((target + 80).truncatingRemainder(dividingBy: 360)) / 0.985647
    date = date.addingTimeInterval((dayOfYear - 2) * 86_400)
    for _ in 0..<25 {
        let lon = sunApparentLongitude(julianDay: julianDay(from: date))
        let diff = signedAngleDelta(target: target, actual: lon)
        date = date.addingTimeInterval(diff * 86_400 / 0.985647)
    }
    return date
}
