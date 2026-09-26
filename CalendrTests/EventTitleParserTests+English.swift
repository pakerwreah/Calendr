//
//  EventTitleParserTests+English.swift
//  CalendrTests
//

import Foundation
import Testing
@testable import Calendr

struct EventTitleParserEnglishTests {

    @Test(arguments: ["14", "2pm", "14:00"])
    func parsesDateAndTime(_ time: String) async {
        let result = await parse("Dinner with mom tomorrow at \(time)")

        #expect(result.cleanedTitle == "Dinner with mom")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 14, minute: 0))
        #expect(result.tokens.map(\.kind) == [.date, .time])
    }

    @Test(arguments: [
        ("Retrospective yesterday", -1),
        ("Planning today", 0),
        ("Planning tomorrow", 1),
        ("Planning in a week", 7),
        ("Planning in one week", 7),
        ("Planning in 3 days", 3),
    ])
    func parsesRelativeDates(_ title: String, _ expectedOffset: Int) async {
        #expect(await parse(title).dayOffset == expectedOffset)
    }

    @Test func parsesRelativeStart() async {
        let result = await parse("Call in 2 hours")

        #expect(result.cleanedTitle == "Call")
        #expect(result.relativeStart == .init(value: 2, unit: .hour))
    }

    @Test func parsesDurationAndAllDay() async {
        let result = await parse("Retreat tomorrow full day for 4 days")

        #expect(result.cleanedTitle == "Retreat")
        #expect(result.dayOffset == 1)
        #expect(result.duration == .init(value: 4, unit: .day))
        #expect(result.isAllDay)
    }

    @Test(arguments: [
        ("Lunch tomorrow at noon", 12),
        ("Deployment tomorrow at midnight", 0),
        ("Coffee tomorrow morning", 9),
        ("Dinner tomorrow in the evening", 18),
        ("Dinner tomorrow at 7 in the evening", 19),
    ])
    func parsesNamedTimesAndDayPeriods(_ title: String, _ expectedHour: Int) async {
        let result = await parse(title)

        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: expectedHour, minute: 0))
    }

    @Test(arguments: ["from 14 to 16", "at 14 until 16"])
    func parsesTimeRange(_ instruction: String) async {
        let result = await parse("Workshop tomorrow \(instruction)")

        #expect(result.cleanedTitle == "Workshop")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 14, minute: 0))
        #expect(result.endTime == .init(hour: 16, minute: 0))
    }

    @Test func parsesNamedDatesInBothEnglishOrders() async {
        let monthFirst = await parse("Birthday on August 12 at noon")
        let dayFirst = await parse("Conference 12 August 2027 at 9")

        #expect(monthFirst.cleanedTitle == "Birthday")
        #expect(monthFirst.numericDate == .init(month: 8, day: 12, year: nil))
        #expect(monthFirst.time == .init(hour: 12, minute: 0))
        #expect(dayFirst.cleanedTitle == "Conference")
        #expect(dayFirst.numericDate == .init(month: 8, day: 12, year: 2027))
        #expect(dayFirst.time == .init(hour: 9, minute: 0))
    }

    @Test func namedDatesStayEnglishWithNonEnglishCalendarLocale() async {
        let result = await parse(
            "Dinner 12 August at 14",
            localeIdentifier: "cs_CZ"
        )

        #expect(result.cleanedTitle == "Dinner")
        #expect(result.numericDate == .init(month: 8, day: 12, year: nil))
        #expect(result.time == .init(hour: 14, minute: 0))
    }

    @Test func doesNotParseLocalizedMonthNames() async {
        let result = await parse(
            "Dinner 12 srpna at 14",
            localeIdentifier: "cs_CZ"
        )

        #expect(result.cleanedTitle == "Dinner 12 srpna")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 14, minute: 0))
    }

    @Test func numericDateOrderFollowsCalendarLocale() async {
        let dayFirst = await parse("Dinner 7.8.", localeIdentifier: "cs_CZ")
        let monthFirst = await parse("Dinner 7.8.", localeIdentifier: "en_US")

        #expect(dayFirst.numericDate == .init(month: 8, day: 7, year: nil))
        #expect(monthFirst.numericDate == .init(month: 7, day: 8, year: nil))
    }

    @Test func parsesNearestFollowingFuzzyAndAbbreviatedWeekdays() async {
        let nearest = await parse("Dinner on Saturday at 14")
        let following = await parse("Dinner next Saturday at 14")
        let fuzzy = await parse("Dinner on satruday at 14")
        let abbreviated = await parse("Brunch on Sun")

        #expect(nearest.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(following.weekday == .init(weekday: 7, occurrence: .following))
        #expect(fuzzy.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(abbreviated.weekday == .init(weekday: 1, occurrence: .nearest))
    }

    @Test func ignoresInvalidNamedDateAndParsesValidTime() async {
        let result = await parse("Meeting February 31 at 9")

        #expect(result.cleanedTitle == "Meeting February 31")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 0))
    }

    @Test func parsesCalendarInstruction() async {
        let result = await parse("Dinner tomorrow at 14 /work")

        #expect(result.cleanedTitle == "Dinner")
        #expect(result.calendarQuery == "work")
        #expect(result.tokens.map(\.kind) == [.date, .time, .calendar])
    }

    @Test func preservesOrdinaryTitle() async {
        let title = "Dinner with mom"
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    @Test(arguments: [
        "Tomorrow planning",
        "August 12 birthday",
        "At 14 lunch",
        "In 2 hours call",
        "Full day workshop",
        "For 2 hours lecture",
        "Tomorrow morning conference",
    ])
    func neverParsesFirstInstruction(_ title: String) async {
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    @Test func doesNotParseCzechInstructions() async {
        let title = "Dinner zítra ve 14"
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    private func parse(
        _ title: String,
        localeIdentifier: String = "en_US"
    ) async -> EventTitleParseResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: localeIdentifier)
        calendar.timeZone = TimeZone(identifier: "Europe/Prague")!

        return await EventTitleParser.parse(
            title,
            calendar: calendar,
            referenceDate: .now,
            language: .english
        )
    }
}
