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
            tokens: []
        )
    }
}

struct EventTitleDateMatch: Equatable {
    let dayOffset: Int?
    let time: EventTitleTime?
    let numericDate: EventTitleNumericDate?
    let weekday: EventTitleWeekday?
}

struct EventTitleTimeMatch: Equatable {
    let time: EventTitleTime
    let endTime: EventTitleTime?
}

struct EventTitleRelativeStartMatch: Equatable {
    let relativeStart: EventTitleRelativeStart
}

struct EventTitleDurationMatch: Equatable {
    let duration: EventTitleDuration
}

extension EventTitleInstructions {

    struct Item<Info: Equatable>: Equatable {
        let range: NSRange
        let info: Info
    }
}

typealias EventTitleDateMatchItem = EventTitleInstructions.Item<EventTitleDateMatch>
typealias EventTitleTimeMatchItem = EventTitleInstructions.Item<EventTitleTimeMatch>
typealias EventTitleRelativeStartMatchItem = EventTitleInstructions.Item<EventTitleRelativeStartMatch>
typealias EventTitleDurationMatchItem = EventTitleInstructions.Item<EventTitleDurationMatch>

/// Everything a language recognised in a title.
struct EventTitleInstructions {
    var dates: [EventTitleDateMatchItem] = []
    var times: [EventTitleTimeMatchItem] = []
    var relativeStarts: [EventTitleRelativeStartMatchItem] = []
    var durations: [EventTitleDurationMatchItem] = []
    var allDayRanges: [NSRange] = []
}

enum EventTitleParser {

    static func parse(
        _ text: String,
        calendar: Calendar,
        referenceDate: Date,
        language: EventTitleParserLanguage
    ) async -> EventTitleParseResult {
        let firstWordRange = firstWordRange(in: text)
        let calendarMatches =
            calendarExpression
            .matches(in: text, range: text.nsRange)
            .compactMap { match -> CalendarMatch? in
                guard
                    let range = validRange(match.range(at: 1)),
                    !overlaps(range, firstWordRange),
                    let queryRange = Range(match.range(at: 2), in: text),
                    let query = String(text[queryRange]).trimmed.notEmpty
                else {
                    return nil
                }
                return (range, query)
            }
        let calendarMatch = calendarMatches.last
        let calendarRanges = calendarMatches.map(\.range)
        let excludedRanges = calendarRanges + [firstWordRange].compactMap { $0 }

        var instructions = await language.parser.instructions(
            in: text,
            calendar: calendar,
            referenceDate: referenceDate,
            excluding: excludedRanges,
            firstWordRange: firstWordRange
        )
        instructions.dates.removeAll { match in
            guard let numericDate = match.info.numericDate else { return false }
            return !isValid(numericDate, calendar: calendar, referenceDate: referenceDate)
        }

        let dateMatch = instructions.dates.first?.info
        let timeMatch = instructions.times.first?.info
        let relativeStartMatch = instructions.relativeStarts.first?.info
        let durationMatch = instructions.durations.first?.info
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
            time: timeMatch?.time ?? dateMatch?.time,
            endTime: timeMatch?.endTime,
            relativeStart: relativeStartMatch?.relativeStart,
            duration: durationMatch?.duration,
            isAllDay: isAllDay,
            calendarQuery: calendarMatch?.query,
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
