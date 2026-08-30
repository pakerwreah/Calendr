//
//  ChineseSolarTerm.swift
//  Calendr
//
//  Created by Paker on 29/08/2026.
//  Authored by Boni (imboni)
//

import Foundation

private let solarTermNames = [
    "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
    "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
    "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
    "立冬", "小雪", "大雪", "冬至"
]

private let gregorianCalendar = Calendar(identifier: .gregorian).with(timeZone: .utc)
private let shanghaiCalendar = Calendar(identifier: .gregorian).with(timeZone: .shanghai)

struct ChineseSolarTerm: Equatable {
    let text: String
}

extension ChineseSolarTerm {

    init?(from date: Date) {
        let year = shanghaiCalendar.component(.year, from: date)
        for yearToCheck in [year - 1, year] {
            for index in solarTermNames.indices {
                guard let termDate = dateOfSolarTerm(year: yearToCheck, index: index) else { continue }
                if shanghaiCalendar.isDate(date, inSameDayAs: termDate) {
                    self.init(text: solarTermNames[index])
                    return
                }
            }
        }
        return nil
    }
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
    guard var date = gregorianCalendar.date(from: DateComponents(year: year, month: 1, day: 1, hour: 0)) else {
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
