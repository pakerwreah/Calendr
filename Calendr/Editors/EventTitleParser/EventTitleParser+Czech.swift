//
//  EventTitleParser+Czech.swift
//  Calendr
//

import Foundation

enum CzechEventTitleParser: EventTitleParsing {

    static func instructions(
        in text: String,
        calendar: Calendar,
        excluding excludedRanges: [NSRange]
    ) -> EventTitleInstructions {

        var instructions = EventTitleInstructions()

        instructions.dates = dateMatches(in: text, calendar: calendar, excluding: excludedRanges)
        instructions.times = timeMatches(
            in: text,
            hasDateInstruction: false,
            excluding: excludedRanges
        )
        let timeRanges = instructions.times.map(\.range)
        instructions.dates.removeAll { date in
            timeRanges.contains { NSIntersectionRange(date.range, $0).length == date.range.length }
        }
        if !instructions.dates.isEmpty {
            // `ráno` and `večer` are ordinary words in Czech, so on their own
            // they only mean a time when the title names a real day. Numeric
            // matches contained in dotted clock times have been removed above.
            instructions.times += timeMatches(
                in: text,
                hasDateInstruction: true,
                excluding: excludedRanges + timeRanges
            )
        }
        instructions.relativeStarts = relativeStartMatches(
            in: text,
            excluding: excludedRanges + instructions.dates.map(\.range) + instructions.times.map(\.range)
        )
        instructions.durations = durationMatches(in: text, excluding: excludedRanges)
        instructions.allDayRanges =
            allDayExpression
            .matches(in: text, range: text.nsRange)
            .map(\.range)
            .filter { !Self.isExcluded($0, by: excludedRanges) }

        return instructions
    }
}

private let localeIdentifier = "cs_CZ"

private let dayPeriods = #"ráno|dopoledne|odpoledne|večer"#

private let timeValuePattern =
    #"(?:\d{1,2}(?:[.:]\d{2})?\s*(?:(?:a\.?m\.?|p\.?m\.?)|(?:"# + dayPeriods
    + #"))?|poledne|půlnoc|půlnoci)"#

private let dateExpressions: [(expression: NSRegularExpression, offset: (NSTextCheckingResult, String) -> Int?)] = [
    (
        regex(#"\bza\s+(?:(?:jeden|1)\s+)?týden\b"#),
        { _, _ in 7 }
    ),
    (
        regex(#"\bza\s+(\d+)\s+(?:den|dny|dnů|dní)\b"#),
        { match, text in
            Range(match.range(at: 1), in: text).flatMap { Int(text[$0]) }
        }
    ),
    (regex(#"\bvčera\b"#), { _, _ in -1 }),
    (regex(#"\bzítra\b"#), { _, _ in 1 }),
    (regex(#"\bdnes\b"#), { _, _ in 0 }),
]

private let timeRangeExpression = regex(
    #"\b(?:od|v|ve)\s+("# + timeValuePattern + #")\s+do\s+("# + timeValuePattern
        + #")(?![\p{L}\p{N}])"#
)

private let timeExpression = regex(#"\b(?:v|ve)\s+("# + timeValuePattern + #")(?![\p{L}\p{N}])"#)

private let midnightExpression = regex(#"\bo\s+(půlnoci)\b"#)

private let linkedDayPeriodExpression = regex(#"\b(?:dnes|zítra|včera)\s+("# + dayPeriods + #")\b"#)

private let dayPeriodExpression = regex(#"\b("# + dayPeriods + #")\b"#)

private let relativeStartExpression = regex(
    #"\bza\s+(\d+)\s*(min(?:\.?|ut(?:a|u|y)?)|hod(?:\.?|in(?:a|u|y)?))(?![\p{L}\p{N}])"#
)

private let namedDateExpression = regex(
    #"(?<![\p{L}\p{N}])(?:dne\s+)?(\d{1,2})\.?\s+([\p{L}.]+)(?:\s+(\d{4}))?\b"#
)

private let weekdayExpression = regex(#"\b(v|ve|příští)\s+([\p{L}]+)\b"#)

private let durationExpression = regex(
    #"\bna\s+(\d+)\s*(min(?:\.?|ut(?:a|u|y)?)|hod(?:\.?|in(?:a|u|y)?)|den|dny|dnů|dní|týden|týdny|týdnů)(?![\p{L}\p{N}])"#
)

private let allDayExpression = regex(#"\b(?:na\s+celý\s+den|celý\s+den|celodenní)\b"#)

private let followingWeekdayWord = CzechEventTitleParser.normalizedParserWord("příští")

private let noonWord = normalizedCzechTimeValue("poledne")

private let midnightWords = ["půlnoc", "půlnoci"].map(normalizedCzechTimeValue)

private let morningSuffixes = ["ráno", "dopoledne"].map(normalizedCzechTimeValue)

private let eveningSuffixes = ["odpoledne", "večer"].map(normalizedCzechTimeValue)

private let dayPeriodTimes = foldedKeys([
    "ráno": EventTitleTime(hour: 9, minute: 0),
    "dopoledne": EventTitleTime(hour: 9, minute: 0),
    "odpoledne": EventTitleTime(hour: 15, minute: 0),
    "večer": EventTitleTime(hour: 18, minute: 0),
])

private let durationUnits = foldedKeys([
    "min": EventTitleDurationUnit.minute,
    "minuta": .minute,
    "minutu": .minute,
    "minuty": .minute,
    "minut": .minute,
    "hod": .hour,
    "hodina": .hour,
    "hodinu": .hour,
    "hodiny": .hour,
    "hodin": .hour,
    "den": .day,
    "dny": .day,
    "dní": .day,
    "dnů": .day,
    "týden": .week,
    "týdny": .week,
    "týdnů": .week,
])

/// Weekdays are named in the nominative, but an instruction puts them in the
/// accusative. Only these three actually change spelling.
private let accusativeWeekdays = [
    EventTitleWeekdayCandidate(
        name: CzechEventTitleParser.normalizedParserWord("neděli"),
        weekday: 1,
        allowsFuzzyMatching: true
    ),
    EventTitleWeekdayCandidate(
        name: CzechEventTitleParser.normalizedParserWord("středu"),
        weekday: 4,
        allowsFuzzyMatching: true
    ),
    EventTitleWeekdayCandidate(
        name: CzechEventTitleParser.normalizedParserWord("sobotu"),
        weekday: 7,
        allowsFuzzyMatching: true
    ),
]

private func dateMatches(
    in text: String,
    calendar: Calendar,
    excluding excludedRanges: [NSRange]
) -> [EventTitleDateMatch] {
    var results: [EventTitleDateMatch] = []

    for candidate in dateExpressions {
        let matches = candidate.expression.matches(in: text, range: text.nsRange)
        for match in matches
        where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
            if let offset = candidate.offset(match, text) {
                results.append(.init(range: match.range, dayOffset: offset, numericDate: nil, weekday: nil))
            }
        }
    }

    results += CzechEventTitleParser.numericDateMatches(
        in: text,
        calendar: calendar,
        excluding: excludedRanges + results.map(\.range)
    )

    for match in namedDateExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let dayRange = Range(match.range(at: 1), in: text),
            let monthRange = Range(match.range(at: 2), in: text),
            let month = CzechEventTitleParser.monthNumber(
                matching: String(text[monthRange]),
                calendar: calendar,
                localeIdentifier: localeIdentifier
            ),
            let day = Int(text[dayRange]),
            (1...31).contains(day)
        else {
            continue
        }

        let year = Range(match.range(at: 3), in: text).flatMap { Int(text[$0]) }
        let date = EventTitleNumericDate(month: month, day: day, year: year)
        results.append(.init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil))
    }

    let weekdayCandidates =
        CzechEventTitleParser.localizedWeekdayCandidates(
            calendar: calendar,
            localeIdentifier: localeIdentifier
        ) + accusativeWeekdays

    for match in weekdayExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let occurrenceRange = Range(match.range(at: 1), in: text),
            let weekdayRange = Range(match.range(at: 2), in: text),
            let weekday = CzechEventTitleParser.weekdayNumber(
                matching: String(text[weekdayRange]),
                in: weekdayCandidates
            )
        else {
            continue
        }
        let occurrence: EventTitleWeekdayOccurrence =
            CzechEventTitleParser.normalizedParserWord(String(text[occurrenceRange]))
                == followingWeekdayWord
            ? .following
            : .nearest
        results.append(
            .init(
                range: match.range,
                dayOffset: nil,
                numericDate: nil,
                weekday: .init(weekday: weekday, occurrence: occurrence)
            ))
    }

    return results
}

private func timeMatches(
    in text: String,
    hasDateInstruction: Bool,
    excluding excludedRanges: [NSRange]
) -> [EventTitleTimeMatch] {
    var results: [EventTitleTimeMatch] = []
    let linkedDayPeriodRanges =
        linkedDayPeriodExpression
        .matches(in: text, range: text.nsRange)
        .map(\.range)

    for match in timeRangeExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let startRange = Range(match.range(at: 1), in: text),
            let endRange = Range(match.range(at: 2), in: text),
            let startTime = parseTime(String(text[startRange])),
            let endTime = parseTime(String(text[endRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, time: startTime, endTime: endTime))
    }

    for match in timeExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let timeRange = Range(match.range(at: 1), in: text),
            let time = parseTime(String(text[timeRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, time: time, endTime: nil))
    }

    for match in midnightExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let timeRange = Range(match.range(at: 1), in: text),
            let time = parseTime(String(text[timeRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, time: time, endTime: nil))
    }

    for match in linkedDayPeriodExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        results.append(.init(range: match.range(at: 1), time: time, endTime: nil))
    }

    guard hasDateInstruction else { return results }

    for match in dayPeriodExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(
        match.range,
        by: excludedRanges + results.map(\.range) + linkedDayPeriodRanges
    ) {
        guard
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, time: time, endTime: nil))
    }
    return results
}

private func relativeStartMatches(
    in text: String,
    excluding excludedRanges: [NSRange]
) -> [EventTitleRelativeStartMatch] {
    var results: [EventTitleRelativeStartMatch] = []

    for match in relativeStartExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, relativeStart: .init(value: value, unit: unit)))
    }
    return results
}

private func durationMatches(
    in text: String,
    excluding excludedRanges: [NSRange]
) -> [EventTitleDurationMatch] {
    var results: [EventTitleDurationMatch] = []

    for match in durationExpression.matches(in: text, range: text.nsRange)
    where !CzechEventTitleParser.isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, duration: .init(value: value, unit: unit)))
    }
    return results
}

private func parseTime(_ text: String) -> EventTitleTime? {
    var value = normalizedCzechTimeValue(text)

    if value == noonWord { return .init(hour: 12, minute: 0) }
    if midnightWords.contains(value) { return .init(hour: 0, minute: 0) }

    let meridiem: EventTitleMeridiem?

    if value.hasSuffix("am") {
        meridiem = .am
        value.removeLast(2)
    } else if value.hasSuffix("pm") {
        meridiem = .pm
        value.removeLast(2)
    } else if let suffix = morningSuffixes.first(where: value.hasSuffix) {
        meridiem = .am
        value.removeLast(suffix.count)
    } else if let suffix = eveningSuffixes.first(where: value.hasSuffix) {
        meridiem = .pm
        value.removeLast(suffix.count)
    } else {
        meridiem = nil
    }

    return CzechEventTitleParser.clockTime(value, meridiem: meridiem)
}

private func normalizedCzechTimeValue(_ value: String) -> String {
    CzechEventTitleParser.normalizedParserWord(value)
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: #"(?<=\d)\.(?=\d)"#, with: ":", options: .regularExpression)
        .replacingOccurrences(of: ".", with: "")
}

private func parseDayPeriod(_ text: String) -> EventTitleTime? {
    dayPeriodTimes[CzechEventTitleParser.normalizedParserWord(text)]
}

private func parseDurationUnit(_ text: String) -> EventTitleDurationUnit? {
    durationUnits[normalizedDurationUnit(text)]
}

/// Czech abbreviates units with a trailing dot, as in `hod.`.
private func normalizedDurationUnit(_ value: String) -> String {
    CzechEventTitleParser.normalizedParserWord(value)
        .trimmingCharacters(in: CharacterSet(charactersIn: "."))
}

private func foldedKeys<Value>(_ words: [String: Value]) -> [String: Value] {
    .init(
        words.map { (normalizedDurationUnit($0.key), $0.value) },
        uniquingKeysWith: { first, _ in first }
    )
}

/// Czech is written with diacritics but often typed without them. Patterns
/// declare the correct spelling only; every accented word is rewritten into an
/// alternation that also accepts the bare form, so `zítra` matches `zitra`.
/// Escape sequences (`\b`, `\p{L}`, …) are stepped over so they stay intact.
private func regex(_ pattern: String) -> NSRegularExpression {
    try! NSRegularExpression(
        pattern: acceptingUnaccentedSpelling(pattern), options: [.caseInsensitive])
}

private func acceptingUnaccentedSpelling(_ pattern: String) -> String {
    var result = ""
    var word = ""

    func flushWord() {
        guard !word.isEmpty else { return }
        let unaccented = word.folding(options: .diacriticInsensitive, locale: nil)
        result += unaccented == word ? word : "(?:\(word)|\(unaccented))"
        word = ""
    }

    var characters = Substring(pattern)

    while let character = characters.popFirst() {
        if character == "\\" {
            flushWord()
            result.append(character)
            if let escaped = characters.popFirst() {
                result.append(escaped)
            }
        } else if character.isLetter {
            word.append(character)
        } else {
            flushWord()
            result.append(character)
        }
    }
    flushWord()

    return result
}
