//
//  EventTitleParser.swift
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

    static func empty() -> Self {
        .init(
            cleanedTitle: "",
            dayOffset: nil,
            numericDate: nil,
            weekday: nil,
            time: nil,
            endTime: nil,
            relativeStart: nil,
            duration: nil,
            isAllDay: false,
            calendarQuery: nil,
            hasConflicts: false,
            tokens: []
        )
    }
}

struct EventTitleDateMatch: Equatable {
    let range: NSRange
    let dayOffset: Int?
    let numericDate: EventTitleNumericDate?
    let weekday: EventTitleWeekday?
}

struct EventTitleTimeMatch: Equatable {
    let range: NSRange
    let time: EventTitleTime
    let endTime: EventTitleTime?
}

struct EventTitleRelativeStartMatch: Equatable {
    let range: NSRange
    let relativeStart: EventTitleRelativeStart
}

struct EventTitleDurationMatch: Equatable {
    let range: NSRange
    let duration: EventTitleDuration
}

/// Everything a language recognised in a title.
struct EventTitleInstructions {
    var dates: [EventTitleDateMatch] = []
    var times: [EventTitleTimeMatch] = []
    var relativeStarts: [EventTitleRelativeStartMatch] = []
    var durations: [EventTitleDurationMatch] = []
    var allDayRanges: [NSRange] = []
}

enum EventTitleParser {

    static func parse(
        _ text: String,
        calendar: Calendar = .current,
        referenceDate: Date = Date(),
        language: EventTitleParserLanguage = .english
    ) -> EventTitleParseResult {
        let protectedRange = firstWordRange(in: text)
        let calendarMatches =
            calendarExpression
            .matches(in: text, range: text.nsRange)
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

        var instructions = language.parser.instructions(
            in: text,
            calendar: calendar,
            excluding: excludedRanges
        )
        instructions.dates.removeAll { match in
            guard let numericDate = match.numericDate else { return false }
            return !isValid(numericDate, calendar: calendar, referenceDate: referenceDate)
        }

        let dateMatch = instructions.dates.first
        let timeMatch = instructions.times.first
        let relativeStartMatch = instructions.relativeStarts.first
        let durationMatch = instructions.durations.first
        let isAllDay = !instructions.allDayRanges.isEmpty

        var tokens = calendarRanges.map { EventTitleToken(kind: .calendar, range: $0) }
        tokens += instructions.dates.map { EventTitleToken(kind: .date, range: $0.range) }
        tokens += instructions.times.map { EventTitleToken(kind: .time, range: $0.range) }
        tokens += instructions.relativeStarts.map { EventTitleToken(kind: .time, range: $0.range) }
        tokens += instructions.durations.map { EventTitleToken(kind: .duration, range: $0.range) }
        tokens += instructions.allDayRanges.map { EventTitleToken(kind: .allDay, range: $0) }

        return .init(
            cleanedTitle: removing(tokens: tokens, from: text),
            dayOffset: dateMatch?.dayOffset,
            numericDate: dateMatch?.numericDate,
            weekday: dateMatch?.weekday,
            time: timeMatch?.time,
            endTime: timeMatch?.endTime,
            relativeStart: relativeStartMatch?.relativeStart,
            duration: durationMatch?.duration,
            isAllDay: isAllDay,
            calendarQuery: calendarMatch?.query,
            hasConflicts: hasConflicts(instructions, calendarMatches: calendarMatches.count),
            tokens: tokens.sorted { $0.range.location < $1.range.location }
        )
    }
}

private func isValid(
    _ numericDate: EventTitleNumericDate,
    calendar: Calendar,
    referenceDate: Date
) -> Bool {
    let components = DateComponents(
        year: numericDate.year ?? calendar.component(.year, from: referenceDate),
        month: numericDate.month,
        day: numericDate.day
    )
    guard let date = calendar.date(from: components) else { return false }

    let resolved = calendar.dateComponents([.year, .month, .day], from: date)
    return resolved.year == components.year
        && resolved.month == components.month
        && resolved.day == components.day
}

private typealias CalendarMatch = (range: NSRange, query: String)

private let calendarExpression = try! NSRegularExpression(
    pattern: #"(?:^|\s)(/([^/\n]+?))(?=\s+(?=/)|\s*$)"#,
    options: [.caseInsensitive]
)

private func hasConflicts(_ instructions: EventTitleInstructions, calendarMatches: Int) -> Bool {

    let isAllDay = !instructions.allDayRanges.isEmpty

    if instructions.dates.count > 1
        || instructions.times.count > 1
        || instructions.relativeStarts.count > 1
        || instructions.durations.count > 1
        || calendarMatches > 1
    {
        return true
    }

    if !instructions.relativeStarts.isEmpty,
        !instructions.dates.isEmpty || !instructions.times.isEmpty
    {
        return true
    }

    if !instructions.durations.isEmpty, instructions.times.contains(where: { $0.endTime != nil }) {
        return true
    }

    if isAllDay {
        if !instructions.times.isEmpty || !instructions.relativeStarts.isEmpty {
            return true
        }
        if instructions.durations.contains(where: { [.minute, .hour].contains($0.duration.unit) }) {
            return true
        }
    }

    return false
}

private func removing(tokens: [EventTitleToken], from text: String) -> String {

    String(text.removingSubranges(RangeSet(tokens.compactMap { Range($0.range, in: text) })))
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func firstWordRange(in text: String) -> NSRange? {
    try! NSRegularExpression(pattern: #"\S+"#)
        .firstMatch(in: text, range: text.nsRange)
        .map(\.range)
}

private func overlaps(_ range: NSRange, _ excludedRange: NSRange?) -> Bool {
    guard let excludedRange else { return false }
    return NSIntersectionRange(range, excludedRange).length > 0
}

private func validRange(_ range: NSRange) -> NSRange? {
    range.location == NSNotFound ? nil : range
}
