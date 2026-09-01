//
//  ChineseLunarCalendarTests.swift
//  CalendrTests
//
//  Created by Paker on 29/08/2026.
//  Authored by Boni (imboni)
//

import Foundation
import Testing
@testable import Calendr

@Suite class ChineseLunarCalendarTests {
    
    let calendar = Calendar(identifier: .gregorian)
    
    @Test func testLunarDayFormatting() {
        // Test various known dates and their lunar equivalents
        // 2026-02-17 is the first day of the Chinese New Year (Year of the Horse)
        let date1: Date = .make(year: 2026, month: 2, day: 17)
        let lunar1 = ChineseLunarDate(from: date1)?.text
        #expect(lunar1 == "正月") // First day of first month shows month name
        
        // 2026-02-18 is the second day of the first lunar month
        let date2: Date = .make(year: 2026, month: 2, day: 18)
        let lunar2 = ChineseLunarDate(from: date2)?.text
        #expect(lunar2 == "初二")
        
        // 2026-02-26 is the tenth day of the first lunar month
        let date3: Date = .make(year: 2026, month: 2, day: 26)
        let lunar3 = ChineseLunarDate(from: date3)?.text
        #expect(lunar3 == "初十")
        
        // 2026-03-08 is the twentieth day of the first lunar month
        let date4: Date = .make(year: 2026, month: 3, day: 8)
        let lunar4 = ChineseLunarDate(from: date4)?.text
        #expect(lunar4 == "二十")
    }

    @Test func testLunarMonthNames() {
        // Test the first day of different lunar months
        // 2026-03-19 is the first day of the second lunar month
        let date1: Date = .make(year: 2026, month: 3, day: 19)
        let lunar1 = ChineseLunarDate(from: date1)?.text
        #expect(lunar1 == "二月")
        
        // 2026-04-17 is the first day of the third lunar month
        let date2: Date = .make(year: 2026, month: 4, day: 17)
        let lunar2 = ChineseLunarDate(from: date2)?.text
        #expect(lunar2 == "三月")
    }
    
    @Test func testLeapMonthFormatting() {
        // 2023 has a leap second month (闰二月)
        // 2023-03-22 is the first day of the leap second month
        let date: Date = .make(year: 2023, month: 3, day: 22)
        let lunar = ChineseLunarDate(from: date)?.text
        #expect(lunar == "闰二月")
    }
    
    @Test func testLunarCalendarInViewModel_withLunarCalendarEnabled() {
        let date: Date = .make(year: 2026, month: 2, day: 17)

        let plugin = makePlugin(for: date)

        #expect(plugin.text == "正月")
    }

    @Test func testGregorianDayNumberFormat() {
        let date: Date = .make(year: 2026, month: 2, day: 17)

        let vm = makeViewModel(for: date)

        // Gregorian day should still be 17
        #expect(vm.text == "17")

        // Lunar date should be the month name
        #expect(vm.plugin?.text == "正月")
    }

    @Test func testSolarTermsFormatting() {
        let date1: Date = .make(year: 2026, month: 2, day: 17)
        let solar1 = ChineseSolarTerm(from: date1)?.text
        #expect(solar1 == nil)

        let date2: Date = .make(year: 2026, month: 2, day: 18)
        let solar2 = ChineseSolarTerm(from: date2)?.text
        #expect(solar2 == "雨水")
    }

    @Test func testSolarTermShouldSupersedeLunarDay() {
        let date: Date = .make(year: 2026, month: 2, day: 18)

        let plugin = makePlugin(for: date)
        #expect(plugin.text == "雨水")
    }

    private func makePlugin(for date: Date) -> ChineseCalendarCellPlugin {
        ChineseCalendarCellPlugin(for: date)
    }

    private func makeViewModel(for date: Date) -> CalendarCellViewModel {
        let plugin = makePlugin(for: date)
        return CalendarCellViewModel(
            date: date,
            inMonth: true,
            isToday: false,
            isSelected: false,
            isHovered: false,
            events: [],
            isHoliday: false,
            dotsStyle: .none,
            calendar: calendar,
            plugin: plugin.eraseToAnyPlugin()
        )
    }
}
