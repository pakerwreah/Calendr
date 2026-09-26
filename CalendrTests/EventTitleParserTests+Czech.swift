//
//  EventTitleParserTests+Czech.swift
//  CalendrTests
//

import Foundation
import Testing

@testable import Calendr

struct EventTitleParserCzechTests {

    @Test func parsesDateTimeAndDuration() async {
        let result = await parse("Večeře s mámou zítra v 14 na 2 hodiny")

        #expect(result.cleanedTitle == "Večeře s mámou")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 14, minute: 0))
        #expect(result.duration == .init(value: 2, unit: .hour))
        #expect(result.tokens.map(\.kind) == [.date, .time, .duration])
    }

    @Test func parsesRelativeStart() async {
        let result = await parse("Volání za 2 hodiny")

        #expect(result.cleanedTitle == "Volání")
        #expect(result.relativeStart == .init(value: 2, unit: .hour))
    }

    @Test func parsesAllDayDuration() async {
        let result = await parse("Dovolená za týden celý den na 4 dny")

        #expect(result.cleanedTitle == "Dovolená")
        #expect(result.dayOffset == 7)
        #expect(result.duration == .init(value: 4, unit: .day))
        #expect(result.isAllDay)
    }

    @Test func parsesNamedDate() async {
        let result = await parse("Konference 12. srpna 2027 v 9")

        #expect(result.cleanedTitle == "Konference")
        #expect(result.numericDate == .init(month: 8, day: 12, year: 2027))
        #expect(result.time == .init(hour: 9, minute: 0))
    }

    @Test func parsesNearestAndFollowingWeekdays() async {
        let nearest = await parse("Tenis v sobotu v 10")
        let following = await parse("Tenis příští sobotu v 10")

        #expect(nearest.cleanedTitle == "Tenis")
        #expect(nearest.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(nearest.time == .init(hour: 10, minute: 0))
        #expect(following.cleanedTitle == "Tenis")
        #expect(following.weekday == .init(weekday: 7, occurrence: .following))
        #expect(following.time == .init(hour: 10, minute: 0))
    }

    @Test func parsesDayPeriodWithWeekday() async {
        let result = await parse("Večeře příští pátek ráno")

        #expect(result.cleanedTitle == "Večeře")
        #expect(result.weekday == .init(weekday: 6, occurrence: .following))
        #expect(result.time == .init(hour: 9, minute: 0))
    }

    @Test func fuzzyMatchesMisspelledWeekday() async {
        let result = await parse("Tenis v sobtu v 10")

        #expect(result.cleanedTitle == "Tenis")
        #expect(result.weekday == .init(weekday: 7, occurrence: .nearest))
        #expect(result.time == .init(hour: 10, minute: 0))
    }

    @Test func parsesDayPeriodsAndNamedTimes() async {
        let morning = await parse("Káva zítra ráno")
        let noon = await parse("Oběd zítra v poledne")

        #expect(morning.cleanedTitle == "Káva")
        #expect(morning.dayOffset == 1)
        #expect(morning.time == .init(hour: 9, minute: 0))
        #expect(noon.cleanedTitle == "Oběd")
        #expect(noon.dayOffset == 1)
        #expect(noon.time == .init(hour: 12, minute: 0))
    }

    @Test func parsesTimeRange() async {
        let result = await parse("Workshop zítra od 10 do 12")

        #expect(result.cleanedTitle == "Workshop")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 10, minute: 0))
        #expect(result.endTime == .init(hour: 12, minute: 0))
    }

    @Test func parsesDottedTimeWithoutTreatingItAsDate() async {
        let result = await parse("Schůzka v 9.10")

        #expect(result.cleanedTitle == "Schůzka")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 10))
    }

    @Test func preservesOrdinaryDayPeriodWithDottedTime() async {
        let result = await parse("Filmový večer v 9.10")

        #expect(result.cleanedTitle == "Filmový večer")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 10))
    }

    @Test func ignoresInvalidNamedDateAndParsesValidTime() async {
        let result = await parse("Schůzka 31. února v 9")

        #expect(result.cleanedTitle == "Schůzka 31. února")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 0))
    }

    @Test func ignoresOutOfRangeNumericDateAndParsesValidTime() async {
        let result = await parse("Schůzka 40.10. v 9")

        #expect(result.cleanedTitle == "Schůzka 40.10.")
        #expect(result.numericDate == nil)
        #expect(result.time == .init(hour: 9, minute: 0))
    }

    @Test func parsesMidnightInInstrumentalCase() async {
        let result = await parse("Schůzka zítra o půlnoci")

        #expect(result.cleanedTitle == "Schůzka")
        #expect(result.dayOffset == 1)
        #expect(result.time == .init(hour: 0, minute: 0))
    }

    @Test func consumesDottedUnitAbbreviations() async {
        let duration = await parse("Schůzka zítra na 2 hod.")
        let relativeStart = await parse("Volání za 30 min.")

        #expect(duration.cleanedTitle == "Schůzka")
        #expect(duration.dayOffset == 1)
        #expect(duration.duration == .init(value: 2, unit: .hour))
        #expect(relativeStart.cleanedTitle == "Volání")
        #expect(relativeStart.relativeStart == .init(value: 30, unit: .minute))
    }

    @Test func consumesAllDayPreposition() async {
        let result = await parse("Dovolená zítra na celý den")

        #expect(result.cleanedTitle == "Dovolená")
        #expect(result.dayOffset == 1)
        #expect(result.isAllDay)
    }

    @Test func supportsInputWithoutDiacritics() async {
        let result = await parse("Tenis pristi sobotu v 7 vecer na 2 hodiny")

        #expect(result.cleanedTitle == "Tenis")
        #expect(result.weekday == .init(weekday: 7, occurrence: .following))
        #expect(result.time == .init(hour: 19, minute: 0))
        #expect(result.duration == .init(value: 2, unit: .hour))
    }

    @Test func preservesOrdinaryDayPeriodWord() async {
        let title = "Filmový večer"
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.time == nil)
        #expect(result.tokens.isEmpty)
    }

    @Test(arguments: [
        "Zítra plánování",
        "Ráno káva",
        "Za 2 hodiny volání",
        "Celý den workshop",
        "Příští sobotu tenis",
    ])
    func neverParsesFirstInstruction(_ title: String) async {
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    @Test func doesNotParseEnglishInstructions() async {
        let title = "Večeře tomorrow at 14"
        let result = await parse(title)

        #expect(result.cleanedTitle == title)
        #expect(result.tokens.isEmpty)
    }

    @Test(arguments: [
        ("Schůze zítra ve 14", "Schůze zitra ve 14"),
        ("Schůze za týden", "Schůze za tyden"),
        ("Schůze příští pátek", "Schůze pristi patek"),
        ("Schůze zítra večer", "Schůze zitra vecer"),
        ("Schůze zítra na 2 týdny", "Schůze zitra na 2 tydny"),
        ("Schůze zítra celý den", "Schůze zitra cely den"),
        ("Schůze zítra v poledne", "Schůze zitra v poledne"),
        ("Schůze zítra o půlnoci", "Schůze zitra o pulnoci"),
    ])
    func acceptsUnaccentedSpelling(_ accented: String, _ unaccented: String) async {
        let accentedResult = await parse(accented)
        let unaccentedResult = await parse(unaccented)

        #expect(accentedResult.dayOffset == unaccentedResult.dayOffset)
        #expect(accentedResult.time == unaccentedResult.time)
        #expect(accentedResult.weekday == unaccentedResult.weekday)
        #expect(accentedResult.duration == unaccentedResult.duration)
        #expect(accentedResult.isAllDay == unaccentedResult.isAllDay)
        #expect(accentedResult.tokens.count == unaccentedResult.tokens.count)
        #expect(accentedResult.tokens.isEmpty == false)
    }

    private func parse(_ title: String) async -> EventTitleParseResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "cs_CZ")
        calendar.timeZone = TimeZone(identifier: "Europe/Prague")!

        return await EventTitleParser.parse(
            title,
            calendar: calendar,
            referenceDate: .now,
            language: .czech
        )
    }
}
