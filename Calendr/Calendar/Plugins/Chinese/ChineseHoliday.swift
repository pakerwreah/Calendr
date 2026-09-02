//
//  ChineseHoliday.swift
//  Calendr
//
//  Created by Paker on 02/09/2026.
//

struct ChineseHoliday: Equatable {
    let text: String

    init?(from title: String) {
        guard
            !title.contains("班"), // exclude make-up workdays
            let short = shortHolidayMapping.first(where: { title.contains($0.key) })
        else {
            return nil
        }

        self.text = short.value
    }
}

/// Lookup table for Chinese holidays.
/// Maps terms included in titles to 2-3 character short strings.
private let shortHolidayMapping: [String: String] = [
    // ------------------------------------------- 2026 ----- //
    "元旦": "元旦",      // New Year's Day          January 1
    "除夕": "除夕",      // Chinese New Year's Eve  February 16
    "春节": "春节",      // Spring Festival         February 17
    "清明": "清明",      // Tomb-Sweeping Day       April 5
    "劳动": "劳动节",    // Labor Day                May 1
    "端午": "端午节",    // Dragon Boat Festival     June 19
    "中秋": "中秋节",    // Mid-Autumn Festival      September 25
    "国庆": "国庆节",    // National Day             October 1
]
