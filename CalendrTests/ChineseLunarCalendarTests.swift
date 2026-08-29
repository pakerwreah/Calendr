//
//  ChineseLunarCalendarTests.swift
//  CalendrTests
//
//  Created by Paker on 28/08/2026.
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
        let lunar1 = chineseLunarDateString(from: date1, calendar: calendar)
        #expect(lunar1 == "正月") // First day of first month shows month name
        
        // 2026-02-18 is the second day of the first lunar month
        let date2: Date = .make(year: 2026, month: 2, day: 18)
        let lunar2 = chineseLunarDateString(from: date2, calendar: calendar)
        #expect(lunar2 == "初二")
        
        // 2026-02-26 is the tenth day of the first lunar month
        let date3: Date = .make(year: 2026, month: 2, day: 26)
        let lunar3 = chineseLunarDateString(from: date3, calendar: calendar)
        #expect(lunar3 == "初十")
        
        // 2026-03-08 is the twentieth day of the first lunar month
        let date4: Date = .make(year: 2026, month: 3, day: 8)
        let lunar4 = chineseLunarDateString(from: date4, calendar: calendar)
        #expect(lunar4 == "二十")
    }
    
    @Test func testLunarMonthNames() {
        // Test the first day of different lunar months
        // 2026-03-19 is the first day of the second lunar month
        let date1: Date = .make(year: 2026, month: 3, day: 19)
        let lunar1 = chineseLunarDateString(from: date1, calendar: calendar)
        #expect(lunar1 == "二月")
        
        // 2026-04-17 is the first day of the third lunar month
        let date2: Date = .make(year: 2026, month: 4, day: 17)
        let lunar2 = chineseLunarDateString(from: date2, calendar: calendar)
        #expect(lunar2 == "三月")
    }
    
    @Test func testLeapMonthFormatting() {
        // 2023 has a leap second month (闰二月)
        // 2023-03-22 is the first day of the leap second month
        let date: Date = .make(year: 2023, month: 3, day: 22)
        let lunar = chineseLunarDateString(from: date, calendar: calendar)
        #expect(lunar == "闰二月")
    }
    
    @Test func testLunarCalendarInViewModel() {
        let date: Date = .make(year: 2026, month: 2, day: 17)
        
        // Test with showLunarCalendar = true
        let vm1 = CalendarCellViewModel(
            date: date,
            inMonth: true,
            isToday: false,
            isSelected: false,
            isHovered: false,
            events: [],
            dotsStyle: .none,
            calendar: calendar,
            showLunarCalendar: true,
            showMainlandHolidays: false,
            showSolarTerms: false
        )
        #expect(vm1.lunarText == "正月")
        
        // Test with showLunarCalendar = false
        let vm2 = CalendarCellViewModel(
            date: date,
            inMonth: true,
            isToday: false,
            isSelected: false,
            isHovered: false,
            events: [],
            dotsStyle: .none,
            calendar: calendar,
            showLunarCalendar: false,
            showMainlandHolidays: false,
            showSolarTerms: false
        )
        #expect(vm2.lunarText == nil)
    }
    
    @Test func testGregorianDayNumberFormat() {
        let date: Date = .make(year: 2026, month: 2, day: 17)
        
        let vm = CalendarCellViewModel(
            date: date,
            inMonth: true,
            isToday: false,
            isSelected: false,
            isHovered: false,
            events: [],
            dotsStyle: .none,
            calendar: calendar,
            showLunarCalendar: true,
            showMainlandHolidays: false,
            showSolarTerms: false
        )
        
        // Gregorian day should still be 17
        #expect(vm.text == "17")
        
        // Lunar date should be the month name
        #expect(vm.lunarText == "正月")
    }
}
