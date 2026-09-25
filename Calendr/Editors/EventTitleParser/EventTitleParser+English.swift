//
//  EventTitleParser+English.swift
//  Calendr
//

import Foundation

enum EnglishEventTitleParser: EventTitleParsing {

    static func instructions(
        in text: String,
        calendar: Calendar,
        referenceDate: Date,
        excluding excludedRanges: [NSRange]
    ) -> EventTitleInstructions {

        var instructions = EventTitleInstructions()

        instructions.dates = dateMatches(in: text, calendar: calendar, excluding: excludedRanges)
        instructions.times = timeMatches(in: text, excluding: excludedRanges)
        instructions.relativeStarts = relativeStartMatches(
            in: text,
            excluding: excludedRanges + instructions.dates.map(\.range) + instructions.times.map(\.range)
        )
        instructions.durations = durationMatches(in: text, excluding: excludedRanges)
        instructions.allDayRanges =
            allDayExpression
            .matches(in: text, range: text.nsRange)
            .map(\.range)
            .filter { !$0.intersects(excludedRanges) }

        return instructions
    }
}

private let localeIdentifier = "en_US"

private let dateExpressions: [(expression: NSRegularExpression, offset: (NSTextCheckingResult, String) -> Int?)] = [
    (
        regex(#"\bin\s+(?:a|one)\s+week\b"#),
        { _, _ in 7 }
    ),
    (
        regex(#"\bin\s+(\d+)\s+days?\b"#),
        { match, text in
            Range(match.range(at: 1), in: text).flatMap { Int(text[$0]) }
        }
    ),
    (regex(#"\byesterday\b"#), { _, _ in -1 }),
    (regex(#"\btomorrow\b"#), { _, _ in 1 }),
    (regex(#"\btoday\b"#), { _, _ in 0 }),
]

private let timeValuePattern =
    #"(?:\d{1,2}(?::\d{2})?\s*(?:(?:a\.?m\.?|p\.?m\.?)|(?:in\s+the\s+(?:morning|evening)))?|noon|midnight)"#

private let timeRangeExpression = regex(
    #"\b(?:from|at)\s+("# + timeValuePattern + #")\s+(?:to|until)\s+("# + timeValuePattern
        + #")(?![\p{L}\p{N}])"#
)

private let timeExpression = regex(#"\bat\s+("# + timeValuePattern + #")(?![\p{L}\p{N}])"#)

private let linkedDayPeriodExpression = regex(
    #"\b(?:today|tomorrow|yesterday)\s+(morning|evening)\b"#)

private let dayPeriodExpression = regex(#"\bin\s+the\s+(morning|evening)\b"#)

private let relativeStartExpression = regex(#"\bin\s+(\d+)\s*(minutes?|mins?|hours?|hrs?)\b"#)

private let namedMonthFirstExpression = regex(
    #"(?<![\p{L}\p{N}])(?:on\s+)?([\p{L}.]+)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?\b"#
)

private let namedDayFirstExpression = regex(
    #"(?<![\p{L}\p{N}])(?:on\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+([\p{L}.]+)(?:\s+(\d{4}))?\b"#
)

private let weekdayExpression = regex(#"\b(on|at|next)\s+([\p{L}]+)\b"#)

private let durationExpression = regex(
    #"\bfor\s+(\d+)\s*(minutes?|mins?|hours?|hrs?|days?|weeks?)\b"#)

private let allDayExpression = regex(#"\b(?:all|full)\s+day\b"#)

private func dateMatches(
    in text: String,
    calendar: Calendar,
    excluding excludedRanges: [NSRange]
) -> [EventTitleDateMatchItem] {
    var results: [EventTitleDateMatchItem] = []

    for candidate in dateExpressions {
        let matches = candidate.expression.matches(in: text, range: text.nsRange)

        for match in matches {
            guard
                !match.range.intersects(excludedRanges + results.map(\.range)),
                let offset = candidate.offset(match, text)
            else {
                continue
            }
            let info = EventTitleDateMatch(dayOffset: offset, numericDate: nil, weekday: nil)

            results.append(.init(range: match.range, info: info))
        }
    }

    results += EnglishEventTitleParser.numericDateMatches(
        in: text,
        calendar: calendar,
        excluding: excludedRanges + results.map(\.range)
    )

    let namedDateExpressions = [
        (namedMonthFirstExpression, 1, 2, 3),
        (namedDayFirstExpression, 2, 1, 3),
    ]
    for (expression, monthGroup, dayGroup, yearGroup) in namedDateExpressions {
        for match in expression.matches(in: text, range: text.nsRange) {
            guard
                !match.range.intersects(excludedRanges + results.map(\.range)),
                let monthRange = Range(match.range(at: monthGroup), in: text),
                let dayRange = Range(match.range(at: dayGroup), in: text),
                let month = EnglishEventTitleParser.monthNumber(
                    matching: String(text[monthRange]),
                    calendar: calendar,
                    localeIdentifier: localeIdentifier
                ),
                let day = Int(text[dayRange]),
                (1...31).contains(day)
            else {
                continue
            }

            let year = Range(match.range(at: yearGroup), in: text).flatMap { Int(text[$0]) }
            let date = EventTitleNumericDate(month: month, day: day, year: year)
            let info = EventTitleDateMatch(dayOffset: nil, numericDate: date, weekday: nil)

            results.append(.init(range: match.range, info: info))
        }
    }

    let weekdayCandidates = EnglishEventTitleParser.localizedWeekdayCandidates(
        calendar: calendar,
        localeIdentifier: localeIdentifier
    )

    for match in weekdayExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let occurrenceRange = Range(match.range(at: 1), in: text),
            let weekdayRange = Range(match.range(at: 2), in: text),
            let weekday = EnglishEventTitleParser.weekdayNumber(
                matching: String(text[weekdayRange]),
                in: weekdayCandidates
            )
        else {
            continue
        }
        let occurrence: EventTitleWeekdayOccurrence =
            text[occurrenceRange].lowercased() == "next"
            ? .following
            : .nearest

        let info = EventTitleDateMatch(
            dayOffset: nil,
            numericDate: nil,
            weekday: .init(weekday: weekday, occurrence: occurrence)
        )

        results.append(.init(range: match.range, info: info))
    }

    return results
}

private func timeMatches(
    in text: String,
    excluding excludedRanges: [NSRange]
) -> [EventTitleTimeMatchItem] {
    var results: [EventTitleTimeMatchItem] = []

    for match in timeRangeExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let startRange = Range(match.range(at: 1), in: text),
            let endRange = Range(match.range(at: 2), in: text),
            let startTime = parseTime(String(text[startRange])),
            let endTime = parseTime(String(text[endRange]))
        else {
            continue
        }
        let info = EventTitleTimeMatch(time: startTime, endTime: endTime)

        results.append(.init(range: match.range, info: info))
    }

    for match in timeExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let timeRange = Range(match.range(at: 1), in: text),
            let time = parseTime(String(text[timeRange]))
        else {
            continue
        }
        let info = EventTitleTimeMatch(time: time, endTime: nil)

        results.append(.init(range: match.range, info: info))
    }

    for match in linkedDayPeriodExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        let info = EventTitleTimeMatch(time: time, endTime: nil)

        results.append(.init(range: match.range(at: 1), info: info))
    }

    for match in dayPeriodExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        let info = EventTitleTimeMatch(time: time, endTime: nil)

        results.append(.init(range: match.range, info: info))
    }
    return results
}

private func relativeStartMatches(
    in text: String,
    excluding excludedRanges: [NSRange]
) -> [EventTitleRelativeStartMatchItem] {
    var results: [EventTitleRelativeStartMatchItem] = []

    for match in relativeStartExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        let info = EventTitleRelativeStartMatch(relativeStart: .init(value: value, unit: unit))

        results.append(.init(range: match.range, info: info))
    }
    return results
}

private func durationMatches(
    in text: String,
    excluding excludedRanges: [NSRange]
) -> [EventTitleDurationMatchItem] {
    var results: [EventTitleDurationMatchItem] = []

    for match in durationExpression.matches(in: text, range: text.nsRange) {
        guard
            !match.range.intersects(excludedRanges + results.map(\.range)),
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        let info = EventTitleDurationMatch(duration: .init(value: value, unit: unit))

        results.append(.init(range: match.range, info: info))
    }
    return results
}

private func parseTime(_ text: String) -> EventTitleTime? {
    var value = EnglishEventTitleParser.normalizedTimeValue(text)

    if value == "noon" { return .init(hour: 12, minute: 0) }
    if value == "midnight" { return .init(hour: 0, minute: 0) }

    let meridiem: EventTitleMeridiem?

    if value.hasSuffix("am") {
        meridiem = .am
        value.removeLast(2)
    } else if value.hasSuffix("pm") {
        meridiem = .pm
        value.removeLast(2)
    } else if value.hasSuffix("inthemorning") {
        meridiem = .am
        value.removeLast("inthemorning".count)
    } else if value.hasSuffix("intheevening") {
        meridiem = .pm
        value.removeLast("intheevening".count)
    } else {
        meridiem = nil
    }

    return EnglishEventTitleParser.clockTime(value, meridiem: meridiem)
}

private func parseDayPeriod(_ text: String) -> EventTitleTime? {
    switch EnglishEventTitleParser.normalizedParserWord(text) {
    case "morning": .init(hour: 9, minute: 0)
    case "evening": .init(hour: 18, minute: 0)
    default: nil
    }
}

private func parseDurationUnit(_ text: String) -> EventTitleDurationUnit? {
    let unit = EnglishEventTitleParser.normalizedParserWord(text)
    if unit.hasPrefix("min") { return .minute }
    if unit.hasPrefix("h") { return .hour }
    if unit.hasPrefix("day") { return .day }
    if unit.hasPrefix("week") { return .week }
    return nil
}

private func regex(_ pattern: String) -> NSRegularExpression {
    try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
}
