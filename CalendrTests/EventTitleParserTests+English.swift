//
//  EventTitleParserTests+English.swift
//  CalendrTests
//

import Foundation
import Testing
@testable import Calendr

struct EventTitleParserEnglishTests {

    @Test(arguments: ["14", "2pm", "14:00"])
    func parsesDateAndTime(_ time: String) {
        let result = parse("Dinner with mom tomorrow at \(time)")

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
    func parsesRelativeDates(_ title: String, _ expectedOffset: Int) {
        #expect(parse(title).dayOffset == expectedOffset)
    }

    @Test func parsesRelativeStart() {
        let result = parse("Call in 2 hours")

        #expect(result.cleanedTitle == "Call")
        #expect(result.relativeStart == .init(value: 2, unit: .hour))
    }

    @Test func parsesDurationAndAllDay() {
        let result = parse("Retreat tomorrow full day for 4 days")

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
    func parsesNamedTimesAndDayPeriods(_ title: String, _ expectedHour: Int) {
        let result = parse(title)

        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: expectedHour, minute: 0))
    }

    @Test(arguments: ["from 14 to 16", "at 14 until 16"])
    func parsesTimeRange(_ instruction: String) {
        let result = parse("Workshop tomorrow \(instruction)")

        #expect(result.cleanedTitle == "Workshop")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 14, minute: 0))
        #expect(result.endTime == .init(hour: 16, minute: 0))
    }

    @Test func parsesNamedDatesInBothEnglishOrders() {
        let monthFirst = parse("Birthday on August 12 at noon")
        let dayFirst = parse("Conference 12 August 2027 at 9")

        #expect(monthFirst.cleanedTitle == "Birthday")
        #expect(monthFirst.numericDate == .init(month: 8, day: 12, year: nil))
        #expect(monthFirst.time == .init(hour: 12, minute: 0))
        #expect(dayFirst.cleanedTitle == "Conference")
        #expect(dayFirst.numericDate == .init(month: 8, day: 12, year: 2027))
        #expect(dayFirst.time == .init(hour: 9, minute: 0))
    }

    @Test func namedDatesStayEnglishWithNonEnglishCalendarLocale() {
        let result = parse(
            "Dinner 12 August at 14",
            localeIdentifier: "cs_CZ"
        )

        #expect(result.cleanedTitle == "Dinner")
        #expect(result.numericDate == .init(month: 8, day: 12, year: nil))
        #expect(result.time == .init(hour: 14, minute: 0))
    }

    @Test func doesNotParseLocalizedMonthNames() {
        let result = parse(
            "Dinner 12 srpna at 14",
            localeIdentifier: "cs_CZ"
        )

        #expect(result.cleanedTitle == "Dinner 12 srpna")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 14, minute: 0))
    }

    @Test func numericDateOrderFollowsCalendarLocale() {
        let dayFirst = parse("Dinner 7.8.", localeIdentifier: "cs_CZ")
        let monthFirst = parse("Dinner 7.8.", localeIdentifier: "en_US")

        #expect(dayFirst.numericDate == .init(month: 8, day: 7, year: nil))
        #expect(monthFirst.numericDate == .init(month: 7, day: 8, year: nil))
    }

    @Test func parsesNearestFollowingFuzzyAndAbbreviatedWeekdays() {
        let nearest = parse("Dinner on Saturday at 14")
        let following = parse("Dinner next Saturday at 14")
        let fuzzy = parse("Dinner on satruday at 14")
        let abbreviated = parse("Brunch on Sun")

        #expect(nearest.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(following.weekday == .init(weekday: 7, occurrence: .following))
        #expect(fuzzy.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(abbreviated.weekday == .init(weekday: 1, occurrence: .nearest))
    }

    @Test func ignoresInvalidNamedDateAndParsesValidTime() {
        let result = parse("Meeting February 31 at 9")

        #expect(result.cleanedTitle == "Meeting February 31")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 0))
        #expect(result.hasConflicts == false)
    }

    @Test(arguments: [
        "Planning tomorrow next Monday 9.9. at 11",
        "Planning at 10 at 11",
        "Planning in 2 hours at 11",
        "Planning tomorrow in 2 hours",
        "Planning for 2 hours for 3 hours",
        "Planning all day at 11",
        "Planning all day in 2 hours",
        "Planning all day for 2 hours",
        "Planning /work /home",
    ])
    func reportsConflictingInstructions(_ title: String) {
        #expect(parse(title).hasConflicts)
    }

    @Test(arguments: [
        "Planning tomorrow at 11 for 2 hours",
        "Planning tomorrow all day for 2 days",
        "Planning in 2 hours for 30 minutes",
        "Planning tomorrow from 10 to 12 /work",
    ])
    func acceptsCompatibleInstructions(_ title: String) {
        #expect(parse(title).hasConflicts == false)
    }

    @Test func parsesCalendarInstruction() {
        let result = parse("Dinner tomorrow at 14 /work")

        #expect(result.cleanedTitle == "Dinner")
        #expect(result.calendarQuery == "work")
        #expect(result.tokens.map(\.kind) == [.date, .time, .calendar])
    }

    @Test func preservesOrdinaryTitle() {
        let title = "Dinner with mom"
        let result = parse(title)

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
    func neverParsesFirstInstruction(_ title: String) {
        let result = parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    @Test func doesNotParseCzechInstructions() {
        let title = "Dinner zítra ve 14"
        let result = parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    private func parse(
        _ title: String,
        localeIdentifier: String = "en_US"
    ) -> EventTitleParseResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: localeIdentifier)
        calendar.timeZone = TimeZone(identifier: "Europe/Prague")!

        return EventTitleParser.parse(
            title,
            calendar: calendar,
            referenceDate: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30),
            language: .english
        )
    }
}
