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
    let tokens: [EventTitleToken]
}

enum EventTitleDateParser {

    static func parse(_ text: String, calendar: Calendar = .current) -> EventTitleParseResult {
        let fullRange = NSRange(text.startIndex..., in: text)
        let protectedRange = firstWordRange(in: text, range: fullRange)
        let calendarMatch = calendarExpression
            .firstMatch(in: text, range: fullRange)
            .flatMap { overlaps($0.range(at: 1), protectedRange) ? nil : $0 }
        let calendarRange = calendarMatch.flatMap { validRange($0.range(at: 1)) }
        let calendarQuery = calendarMatch
            .flatMap { Range($0.range(at: 2), in: text) }
            .map { String(text[$0]).trimmed }
            .flatMap(\.notEmpty)

        var tokens: [EventTitleToken] = calendarRange.map {
            [.init(kind: .calendar, range: $0)]
        } ?? []

        let dateMatch = firstDateMatch(
            in: text,
            range: fullRange,
            calendar: calendar,
            excluding: [calendarRange, protectedRange].compactMap { $0 }
        )
        if let dateMatch {
            tokens.append(.init(kind: .date, range: dateMatch.range))
        }

        let excludedRanges = [calendarRange, protectedRange].compactMap { $0 }
        let timeMatch = firstTimeMatch(in: text, range: fullRange, excluding: excludedRanges)
        if let timeMatch {
            tokens.append(.init(kind: .time, range: timeMatch.range))
        }

        let relativeStartMatch = firstRelativeStartMatch(
            in: text,
            range: fullRange,
            excluding: excludedRanges + tokens.map(\.range)
        )
        if let relativeStartMatch {
            tokens.append(.init(kind: .time, range: relativeStartMatch.range))
        }

        let durationMatch = firstDurationMatch(in: text, range: fullRange, excluding: excludedRanges)
        if let durationMatch {
            tokens.append(.init(kind: .duration, range: durationMatch.range))
        }

        let allDayRange = firstMatch(
            using: allDayExpression,
            in: text,
            range: fullRange,
            excluding: excludedRanges
        )?.range
        if let allDayRange {
            tokens.append(.init(kind: .allDay, range: allDayRange))
        }

        return .init(
            cleanedTitle: removing(tokens: tokens, from: text),
            dayOffset: dateMatch?.dayOffset,
            numericDate: dateMatch?.numericDate,
            weekday: dateMatch?.weekday,
            time: timeMatch?.time,
            endTime: timeMatch?.endTime,
            relativeStart: relativeStartMatch?.relativeStart,
            duration: durationMatch?.duration,
            isAllDay: allDayRange != nil,
            calendarQuery: calendarQuery,
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

private let calendarExpression = try! NSRegularExpression(
    pattern: #"(?:^|\s)(/([^/\n]+?))\s*$"#,
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

private func firstDateMatch(
    in text: String,
    range: NSRange,
    calendar: Calendar,
    excluding excludedRanges: [NSRange]
) -> DateMatch? {
    for candidate in dateExpressions {
        let matches = candidate.expression.matches(in: text, range: range)
        for match in matches where !isExcluded(match.range, by: excludedRanges) {
            if let offset = candidate.offset(match, text) {
                return .init(range: match.range, dayOffset: offset, numericDate: nil, weekday: nil)
            }
        }
    }

    for match in numericDateExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
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
        return .init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil)
    }

    let namedDateExpressions = [
        (namedMonthFirstExpression, 1, 2, 3),
        (namedDayFirstExpression, 2, 1, 3),
    ]
    for (expression, monthGroup, dayGroup, yearGroup) in namedDateExpressions {
        for match in expression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
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
            return .init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil)
        }
    }

    for match in weekdayExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
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
        return .init(
            range: match.range,
            dayOffset: nil,
            numericDate: nil,
            weekday: .init(weekday: weekday, occurrence: occurrence)
        )
    }

    return nil
}

private func firstTimeMatch(in text: String, range: NSRange, excluding excludedRanges: [NSRange]) -> TimeMatch? {
    for match in timeRangeExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let startRange = Range(match.range(at: 1), in: text),
            let endRange = Range(match.range(at: 2), in: text),
            let startTime = parseTime(String(text[startRange])),
            let endTime = parseTime(String(text[endRange]))
        else {
            continue
        }
        return .init(range: match.range, time: startTime, endTime: endTime)
    }

    for match in timeExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let timeRange = Range(match.range(at: 1), in: text),
            let time = parseTime(String(text[timeRange]))
        else {
            continue
        }
        return .init(range: match.range, time: time, endTime: nil)
    }

    for match in linkedDayPeriodExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        return .init(range: match.range(at: 1), time: time, endTime: nil)
    }

    for match in dayPeriodExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let periodRange = Range(match.range(at: 1), in: text),
            let time = parseDayPeriod(String(text[periodRange]))
        else {
            continue
        }
        return .init(range: match.range, time: time, endTime: nil)
    }
    return nil
}

private func firstRelativeStartMatch(
    in text: String,
    range: NSRange,
    excluding excludedRanges: [NSRange]
) -> RelativeStartMatch? {
    for match in relativeStartExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        return (match.range, .init(value: value, unit: unit))
    }
    return nil
}

private func firstDurationMatch(in text: String, range: NSRange, excluding excludedRanges: [NSRange]) -> DurationMatch? {
    for match in durationExpression.matches(in: text, range: range) where !isExcluded(match.range, by: excludedRanges) {
        guard
            let valueRange = Range(match.range(at: 1), in: text),
            let unitRange = Range(match.range(at: 2), in: text),
            let value = Int(text[valueRange]),
            value > 0,
            let unit = parseDurationUnit(String(text[unitRange]))
        else {
            continue
        }
        return (match.range, .init(value: value, unit: unit))
    }
    return nil
}

private func firstMatch(
    using expression: NSRegularExpression,
    in text: String,
    range: NSRange,
    excluding excludedRanges: [NSRange]
) -> NSTextCheckingResult? {
    expression.matches(in: text, range: range).first { !isExcluded($0.range, by: excludedRanges) }
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

private func removing(tokens: [EventTitleToken], from text: String) -> String {
    let result = NSMutableString(string: text)
    for token in tokens.sorted(by: { $0.range.location > $1.range.location }) {
        result.deleteCharacters(in: token.range)
    }

    return String(result)
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
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
