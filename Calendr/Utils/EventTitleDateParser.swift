//
//  EventTitleDateParser.swift
//  Calendr
//

import Foundation

enum EventTitleTokenKind: Equatable {
    case date
    case time
    case duration
    case allDay
    case calendar
}

struct EventTitleToken: Equatable {
    let kind: EventTitleTokenKind
    let range: NSRange
}

struct EventTitleTime: Equatable {
    let hour: Int
    let minute: Int
}

struct EventTitleNumericDate: Equatable {
    let month: Int
    let day: Int
    let year: Int?
}

enum EventTitleWeekdayOccurrence: Equatable {
    case nearest
    case following
}

struct EventTitleWeekday: Equatable {
    let weekday: Int
    let occurrence: EventTitleWeekdayOccurrence
}

enum EventTitleDurationUnit: Equatable {
    case minute
    case hour
    case day
    case week
}

struct EventTitleDuration: Equatable {
    let value: Int
    let unit: EventTitleDurationUnit
}

struct EventTitleRelativeStart: Equatable {
    let value: Int
    let unit: EventTitleDurationUnit
}

struct EventTitleParseResult: Equatable {
    let cleanedTitle: String
    let dayOffset: Int?
    let numericDate: EventTitleNumericDate?
    let weekday: EventTitleWeekday?
    let time: EventTitleTime?
    let endTime: EventTitleTime?
    let relativeStart: EventTitleRelativeStart?
    let duration: EventTitleDuration?
    let isAllDay: Bool
    let calendarQuery: String?
    let hasConflicts: Bool
    let tokens: [EventTitleToken]
}

enum EventTitleDateParser {

    static func parse(_ text: String, calendar: Calendar = .current) -> EventTitleParseResult {
        let fullRange = NSRange(text.startIndex..., in: text)
        let protectedRange = firstWordRange(in: text, range: fullRange)
        let calendarMatches = calendarExpression
            .matches(in: text, range: fullRange)
            .compactMap { match -> CalendarMatch? in
                guard
                    let range = validRange(match.range(at: 1)),
                    !overlaps(range, protectedRange),
                    let queryRange = Range(match.range(at: 2), in: text),
                    let query = String(text[queryRange]).trimmed.notEmpty
                else {
                    return nil
                }
                return (range, query)
            }
        let calendarMatch = calendarMatches.last
        let calendarRanges = calendarMatches.map(\.range)
        let excludedRanges = calendarRanges + [protectedRange].compactMap { $0 }

        let dateMatches = dateMatches(
            in: text,
            range: fullRange,
            calendar: calendar,
            excluding: excludedRanges
        )
        let timeMatches = timeMatches(in: text, range: fullRange, excluding: excludedRanges)
        let relativeStartMatches = relativeStartMatches(
            in: text,
            range: fullRange,
            excluding: excludedRanges + dateMatches.map(\.range) + timeMatches.map(\.range)
        )
        let durationMatches = durationMatches(in: text, range: fullRange, excluding: excludedRanges)
        let allDayRanges = allDayExpression
            .matches(in: text, range: fullRange)
            .map(\.range)
            .filter { !isExcluded($0, by: excludedRanges) }

        let dateMatch = dateMatches.first
        let timeMatch = timeMatches.first
        let relativeStartMatch = relativeStartMatches.first
        let durationMatch = durationMatches.first

        var tokens = calendarRanges.map { EventTitleToken(kind: .calendar, range: $0) }
        tokens += dateMatches.map { EventTitleToken(kind: .date, range: $0.range) }
        tokens += timeMatches.map { EventTitleToken(kind: .time, range: $0.range) }
        tokens += relativeStartMatches.map { EventTitleToken(kind: .time, range: $0.range) }
        tokens += durationMatches.map { EventTitleToken(kind: .duration, range: $0.range) }
        tokens += allDayRanges.map { EventTitleToken(kind: .allDay, range: $0) }

        return .init(
            cleanedTitle: removing(tokens: tokens, from: text),
            dayOffset: dateMatch?.dayOffset,
            numericDate: dateMatch?.numericDate,
            weekday: dateMatch?.weekday,
            time: timeMatch?.time,
            endTime: timeMatch?.endTime,
            relativeStart: relativeStartMatch?.relativeStart,
            duration: durationMatch?.duration,
            isAllDay: !allDayRanges.isEmpty,
            calendarQuery: calendarMatch?.query,
            hasConflicts: hasConflicts(
                dateMatches: dateMatches,
                timeMatches: timeMatches,
                relativeStartMatches: relativeStartMatches,
                durationMatches: durationMatches,
                isAllDay: !allDayRanges.isEmpty,
                calendarMatches: calendarMatches
            ),
            tokens: tokens.sorted { $0.range.location < $1.range.location }
        )
    }
}

private struct DateMatch {
    let range: NSRange
    let dayOffset: Int?
    let numericDate: EventTitleNumericDate?
    let weekday: EventTitleWeekday?
}

private struct TimeMatch {
    let range: NSRange
    let time: EventTitleTime
    let endTime: EventTitleTime?
}

private typealias RelativeStartMatch = (range: NSRange, relativeStart: EventTitleRelativeStart)
private typealias DurationMatch = (range: NSRange, duration: EventTitleDuration)
private typealias CalendarMatch = (range: NSRange, query: String)

private let calendarExpression = try! NSRegularExpression(
    pattern: #"(?:^|\s)(/([^/\n]+?))(?=\s+(?=/)|\s*$)"#,
    options: [.caseInsensitive]
)

private let dateExpressions: [(expression: NSRegularExpression, offset: (NSTextCheckingResult, String) -> Int?)] = [
    (
        try! NSRegularExpression(pattern: #"\bin\s+(?:a|one)\s+week\b"#, options: [.caseInsensitive]),
        { _, _ in 7 }
    ),
    (
        try! NSRegularExpression(pattern: #"\bin\s+(\d+)\s+days?\b"#, options: [.caseInsensitive]),
        { match, text in
            Range(match.range(at: 1), in: text).flatMap { Int(text[$0]) }
        }
    ),
    (
        try! NSRegularExpression(pattern: #"\byesterday\b"#, options: [.caseInsensitive]),
        { _, _ in -1 }
    ),
    (
        try! NSRegularExpression(pattern: #"\btomorrow\b"#, options: [.caseInsensitive]),
        { _, _ in 1 }
    ),
    (
        try! NSRegularExpression(pattern: #"\btoday\b"#, options: [.caseInsensitive]),
        { _, _ in 0 }
    ),
]

private let timeValuePattern = #"(?:\d{1,2}(?::\d{2})?\s*(?:(?:a\.?m\.?|p\.?m\.?)|(?:in\s+the\s+(?:morning|evening)))?|noon|midnight)"#

private let timeRangeExpression = try! NSRegularExpression(
    pattern: #"\b(?:from|at)\s+("# + timeValuePattern + #")\s+(?:to|until)\s+("# + timeValuePattern + #")(?![\p{L}\p{N}])"#,
    options: [.caseInsensitive]
)

private let timeExpression = try! NSRegularExpression(
    pattern: #"\bat\s+("# + timeValuePattern + #")(?![\p{L}\p{N}])"#,
    options: [.caseInsensitive]
)

private let linkedDayPeriodExpression = try! NSRegularExpression(
    pattern: #"\b(?:today|tomorrow|yesterday)\s+(morning|evening)\b"#,
    options: [.caseInsensitive]
)

private let dayPeriodExpression = try! NSRegularExpression(
    pattern: #"\bin\s+the\s+(morning|evening)\b"#,
    options: [.caseInsensitive]
)

private let relativeStartExpression = try! NSRegularExpression(
    pattern: #"\bin\s+(\d+)\s*(minutes?|mins?|hours?|hrs?)\b"#,
    options: [.caseInsensitive]
)

private let numericDateExpression = try! NSRegularExpression(
    pattern: #"(?<!\d)(\d{1,2})\s*[./-]\s*(\d{1,2})(?:\s*[./-]\s*(\d{2,4}))?\.?(?!\d)"#
)

private let namedMonthFirstExpression = try! NSRegularExpression(
    pattern: #"(?<![\p{L}\p{N}])(?:on\s+)?([\p{L}.]+)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?\b"#,
    options: [.caseInsensitive]
)

private let namedDayFirstExpression = try! NSRegularExpression(
    pattern: #"(?<![\p{L}\p{N}])(?:on\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+([\p{L}.]+)(?:\s+(\d{4}))?\b"#,
    options: [.caseInsensitive]
)

private let weekdayExpression = try! NSRegularExpression(
    pattern: #"\b(on|at|next)\s+([\p{L}]+)\b"#,
    options: [.caseInsensitive]
)

private let durationExpression = try! NSRegularExpression(
    pattern: #"\bfor\s+(\d+)\s*(minutes?|mins?|hours?|hrs?|days?|weeks?)\b"#,
    options: [.caseInsensitive]
)

private let allDayExpression = try! NSRegularExpression(
    pattern: #"\b(?:all|full)\s+day\b"#,
    options: [.caseInsensitive]
)

private func dateMatches(
    in text: String,
    range: NSRange,
    calendar: Calendar,
    excluding excludedRanges: [NSRange]
) -> [DateMatch] {
    var results: [DateMatch] = []

    for candidate in dateExpressions {
        let matches = candidate.expression.matches(in: text, range: range)
        for match in matches where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
            if let offset = candidate.offset(match, text) {
                results.append(.init(range: match.range, dayOffset: offset, numericDate: nil, weekday: nil))
            }
        }
    }

    for match in numericDateExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let firstRange = Range(match.range(at: 1), in: text),
            let secondRange = Range(match.range(at: 2), in: text),
            let first = Int(text[firstRange]),
            let second = Int(text[secondRange])
        else {
            continue
        }

        let year = Range(match.range(at: 3), in: text)
            .flatMap { Int(text[$0]) }
            .map { $0 < 100 ? 2000 + $0 : $0 }
        let date = isDayBeforeMonth(in: calendar)
            ? EventTitleNumericDate(month: second, day: first, year: year)
            : EventTitleNumericDate(month: first, day: second, year: year)

        guard (1...12).contains(date.month), (1...31).contains(date.day) else { continue }
        results.append(.init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil))
    }

    let namedDateExpressions = [
        (namedMonthFirstExpression, 1, 2, 3),
        (namedDayFirstExpression, 2, 1, 3),
    ]
    for (expression, monthGroup, dayGroup, yearGroup) in namedDateExpressions {
        for match in expression.matches(in: text, range: range)
            where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
            guard
                let monthRange = Range(match.range(at: monthGroup), in: text),
                let dayRange = Range(match.range(at: dayGroup), in: text),
                let month = matchMonth(String(text[monthRange]), calendar: calendar),
                let day = Int(text[dayRange]),
                (1...31).contains(day)
            else {
                continue
            }

            let year = Range(match.range(at: yearGroup), in: text).flatMap { Int(text[$0]) }
            let date = EventTitleNumericDate(month: month, day: day, year: year)
            results.append(.init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil))
        }
    }

    for match in weekdayExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let occurrenceRange = Range(match.range(at: 1), in: text),
            let weekdayRange = Range(match.range(at: 2), in: text),
            let weekday = matchWeekday(String(text[weekdayRange]), calendar: calendar)
        else {
            continue
        }
        let occurrence: EventTitleWeekdayOccurrence = text[occurrenceRange].lowercased() == "next"
            ? .following
            : .nearest
        results.append(.init(
            range: match.range,
            dayOffset: nil,
            numericDate: nil,
            weekday: .init(weekday: weekday, occurrence: occurrence)
        ))
    }

    return results
}

private func timeMatches(in text: String, range: NSRange, excluding excludedRanges: [NSRange]) -> [TimeMatch] {
    var results: [TimeMatch] = []

    for match in timeRangeExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
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

    for match in timeExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let timeRange = Range(match.range(at: 1), in: text),
            let time = parseTime(String(text[timeRange]))
        else {
            continue
        }
        results.append(.init(range: match.range, time: time, endTime: nil))
    }

    for match in linkedDayPeriodExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        results.append(.init(range: match.range(at: 1), time: time, endTime: nil))
    }

    for match in dayPeriodExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
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
    range: NSRange,
    excluding excludedRanges: [NSRange]
) -> [RelativeStartMatch] {
    var results: [RelativeStartMatch] = []

    for match in relativeStartExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        results.append((match.range, .init(value: value, unit: unit)))
    }
    return results
}

private func durationMatches(in text: String, range: NSRange, excluding excludedRanges: [NSRange]) -> [DurationMatch] {
    var results: [DurationMatch] = []

    for match in durationExpression.matches(in: text, range: range)
        where !isExcluded(match.range, by: excludedRanges + results.map(\.range)) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        results.append((match.range, .init(value: value, unit: unit)))
    }
    return results
}

private func hasConflicts(
    dateMatches: [DateMatch],
    timeMatches: [TimeMatch],
    relativeStartMatches: [RelativeStartMatch],
    durationMatches: [DurationMatch],
    isAllDay: Bool,
    calendarMatches: [CalendarMatch]
) -> Bool {
    if dateMatches.count > 1
        || timeMatches.count > 1
        || relativeStartMatches.count > 1
        || durationMatches.count > 1
        || calendarMatches.count > 1 {
        return true
    }

    if !relativeStartMatches.isEmpty, !dateMatches.isEmpty || !timeMatches.isEmpty {
        return true
    }

    if !durationMatches.isEmpty, timeMatches.contains(where: { $0.endTime != nil }) {
        return true
    }

    if isAllDay {
        if !timeMatches.isEmpty || !relativeStartMatches.isEmpty {
            return true
        }
        if durationMatches.contains(where: { [.minute, .hour].contains($0.duration.unit) }) {
            return true
        }
    }

    return false
}

private func parseTime(_ text: String) -> EventTitleTime? {
    var value = text.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: ".", with: "")

    if value == "noon" { return .init(hour: 12, minute: 0) }
    if value == "midnight" { return .init(hour: 0, minute: 0) }

    let meridiem: Character?

    if value.hasSuffix("am") {
        meridiem = "a"
        value.removeLast(2)
    } else if value.hasSuffix("pm") {
        meridiem = "p"
        value.removeLast(2)
    } else if value.hasSuffix("inthemorning") {
        meridiem = "a"
        value.removeLast("inthemorning".count)
    } else if value.hasSuffix("intheevening") {
        meridiem = "p"
        value.removeLast("intheevening".count)
    } else {
        meridiem = nil
    }

    let components = value.split(separator: ":", omittingEmptySubsequences: false)
    guard
        components.count == 1 || components.count == 2,
        let parsedHour = Int(components[0]),
        let minute = components.count == 2 ? Int(components[1]) : 0,
        (0...59).contains(minute)
    else {
        return nil
    }

    if let meridiem {
        guard (1...12).contains(parsedHour) else { return nil }
        return .init(hour: parsedHour % 12 + (meridiem == "p" ? 12 : 0), minute: minute)
    }

    guard (0...23).contains(parsedHour) else { return nil }
    return .init(hour: parsedHour, minute: minute)
}

private func parseDayPeriod(_ text: String) -> EventTitleTime? {
    switch text.lowercased() {
    case "morning": return .init(hour: 9, minute: 0)
    case "evening": return .init(hour: 18, minute: 0)
    default: return nil
    }
}

private func parseDurationUnit(_ text: String) -> EventTitleDurationUnit? {
    let unit = text.lowercased()
    if unit.hasPrefix("min") { return .minute }
    if unit.hasPrefix("h") { return .hour }
    if unit.hasPrefix("day") { return .day }
    if unit.hasPrefix("week") { return .week }
    return nil
}

private func isDayBeforeMonth(in calendar: Calendar) -> Bool {
    let locale = calendar.locale ?? .current
    guard let format = DateFormatter.dateFormat(fromTemplate: "Md", options: 0, locale: locale) else {
        return false
    }
    guard let day = format.firstIndex(of: "d"), let month = format.firstIndex(of: "M") else {
        return false
    }
    return day < month
}

private func matchMonth(_ input: String, calendar: Calendar) -> Int? {
    let input = normalizedDateWord(input)
    var englishCalendar = calendar
    englishCalendar.locale = Locale(identifier: "en_US")
    let formatter = DateFormatter(calendar: englishCalendar)

    let symbolSets: [[String]] = [
        formatter.monthSymbols,
        formatter.shortMonthSymbols,
        formatter.standaloneMonthSymbols,
        formatter.shortStandaloneMonthSymbols,
    ].compactMap { $0 }
    for symbols in symbolSets {
        if let index = symbols.firstIndex(where: { normalizedDateWord($0) == input }) {
            return index + 1
        }
    }
    return nil
}

private func matchWeekday(_ input: String, calendar: Calendar) -> Int? {
    let input = normalizedWeekday(input)
    let candidates = weekdayCandidates(calendar: calendar)

    if let exact = candidates.first(where: { $0.name == input }) {
        return exact.weekday
    }

    let fuzzyMatches = candidates
        .filter(\.allowsFuzzyMatching)
        .map { ($0.weekday, editDistance(input, $0.name), $0.name.count) }
        .filter { _, distance, length in distance <= (length >= 7 ? 2 : 1) }

    return fuzzyMatches.min {
        if $0.1 == $1.1 { return $0.2 < $1.2 }
        return $0.1 < $1.1
    }?.0
}

private func weekdayCandidates(calendar: Calendar) -> [(name: String, weekday: Int, allowsFuzzyMatching: Bool)] {
    var englishCalendar = calendar
    englishCalendar.locale = Locale(identifier: "en_US")
    let formatter = DateFormatter(calendar: englishCalendar)

    var result: [(String, Int, Bool)] = []
    for (index, name) in formatter.weekdaySymbols.enumerated() {
        result.append((normalizedWeekday(name), index + 1, true))
    }
    for (index, name) in formatter.shortWeekdaySymbols.enumerated() {
        result.append((normalizedWeekday(name), index + 1, false))
    }
    return result
}

private func normalizedWeekday(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
}

private func normalizedDateWord(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
        .trimmingCharacters(in: CharacterSet.punctuationCharacters)
}

private func editDistance(_ lhs: String, _ rhs: String) -> Int {
    let lhs = Array(lhs)
    let rhs = Array(rhs)
    var previous = Array(0...rhs.count)

    for (lhsIndex, lhsCharacter) in lhs.enumerated() {
        var current = [lhsIndex + 1]
        for (rhsIndex, rhsCharacter) in rhs.enumerated() {
            current.append([
                current[rhsIndex] + 1,
                previous[rhsIndex + 1] + 1,
                previous[rhsIndex] + (lhsCharacter == rhsCharacter ? 0 : 1),
            ].min()!)
        }
        previous = current
    }
    return previous[rhs.count]
}

// TODO: use `removingSubranges` when we drop support for macOS 14
private func removing(tokens: [EventTitleToken], from text: String) -> String {

    // Different matchers can claim overlapping ranges for the same characters
    // e.g. "at 9" (time) and "9.30" (numeric date) both cover the "9" in "Meeting at 9.30"
    let ranges = mergeRanges(tokens.map(\.range))

    var result = text

    for nsRange in ranges.sorted(by: { $0.location > $1.location }) {
        if let range = Range(nsRange, in: text) {
            result.removeSubrange(range)
        }
    }

    return result
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func mergeRanges(_ ranges: [NSRange]) -> [NSRange] {
    let sorted = ranges.sorted(by: { $0.location < $1.location })
    guard let first = sorted.first else { return [] }

    var merged: [NSRange] = [first]
    for range in sorted.dropFirst() {
        let last = merged.last!

        if range.location <= NSMaxRange(last) {
            merged[merged.count - 1] = NSUnionRange(last, range)
        } else {
            merged.append(range)
        }
    }
    return merged
}

private func firstWordRange(in text: String, range: NSRange) -> NSRange? {
    try! NSRegularExpression(pattern: #"\S+"#)
        .firstMatch(in: text, range: range)
        .map(\.range)
}

private func isExcluded(_ range: NSRange, by excludedRanges: [NSRange]) -> Bool {
    excludedRanges.contains { overlaps(range, $0) }
}

private func overlaps(_ range: NSRange, _ excludedRange: NSRange?) -> Bool {
    guard let excludedRange else { return false }
    return NSIntersectionRange(range, excludedRange).length > 0
}

private func validRange(_ range: NSRange) -> NSRange? {
    range.location == NSNotFound ? nil : range
}
