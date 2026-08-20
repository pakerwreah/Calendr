//
//  EventTitleParsing.swift
//  Calendr
//

import Foundation

/// Languages differ in more than vocabulary — which instructions take
/// precedence, and when a word counts as an instruction at all, are part of the
/// grammar. Each language recognises its instructions on its own terms and
/// decides the order it matches them in.
protocol EventTitleParsing {

    static func instructions(
        in text: String,
        calendar: Calendar,
        excluding excludedRanges: [NSRange]
    ) -> EventTitleInstructions
}

enum EventTitleMeridiem {
    case am
    case pm
}

struct EventTitleWeekdayCandidate {
    let name: String
    let weekday: Int
    let allowsFuzzyMatching: Bool
}

private let numericDateExpression = try! NSRegularExpression(
    pattern: #"(?<!\d)(\d{1,2})\s*[./-]\s*(\d{1,2})(?:\s*[./-]\s*(\d{2,4}))?\.?(?!\d)"#
)

/// Helpers shared by every `EventTitleParsing` implementation.
///
/// Only genuinely language-neutral behaviour belongs here — digits, ranges and
/// calendar symbols. Anything built out of words is part of a language's own
/// grammar and lives in its parser.
extension EventTitleParsing {

    /// Dates written in digits. The day/month order follows the active locale,
    /// so this reads the same in every language.
    static func numericDateMatches(
        in text: String,
        calendar: Calendar,
        excluding excludedRanges: [NSRange]
    ) -> [EventTitleDateMatch] {
        var results: [EventTitleDateMatch] = []

        for match in numericDateExpression.matches(in: text, range: text.nsRange)
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
            let date =
                isDayBeforeMonth(in: calendar)
                ? EventTitleNumericDate(month: second, day: first, year: year)
                : EventTitleNumericDate(month: first, day: second, year: year)

            guard (1...12).contains(date.month), (1...31).contains(date.day) else { continue }
            results.append(.init(range: match.range, dayOffset: nil, numericDate: date, weekday: nil))
        }

        return results
    }

    /// The digits of a clock time, once a language has stripped its own wording.
    static func clockTime(_ value: String, meridiem: EventTitleMeridiem?) -> EventTitleTime? {
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
            return .init(hour: parsedHour % 12 + (meridiem == .pm ? 12 : 0), minute: minute)
        }

        guard (0...23).contains(parsedHour) else { return nil }
        return .init(hour: parsedHour, minute: minute)
    }

    static func monthNumber(matching input: String, calendar: Calendar, localeIdentifier: String)
        -> Int?
    {
        let input = normalizedDateWord(input)
        let formatter = DateFormatter(calendar: localizedCalendar(calendar, localeIdentifier))

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

    /// Weekday names as the calendar spells them. A language adds its own
    /// inflections on top before matching.
    static func localizedWeekdayCandidates(
        calendar: Calendar,
        localeIdentifier: String
    ) -> [EventTitleWeekdayCandidate] {
        let formatter = DateFormatter(calendar: localizedCalendar(calendar, localeIdentifier))

        var result: [EventTitleWeekdayCandidate] = []
        for (index, name) in formatter.weekdaySymbols.enumerated() {
            result.append(
                .init(name: normalizedParserWord(name), weekday: index + 1, allowsFuzzyMatching: true))
        }
        for (index, name) in formatter.shortWeekdaySymbols.enumerated() {
            result.append(
                .init(name: normalizedParserWord(name), weekday: index + 1, allowsFuzzyMatching: false))
        }
        return result
    }

    static func weekdayNumber(matching input: String, in candidates: [EventTitleWeekdayCandidate])
        -> Int?
    {
        let input = normalizedParserWord(input)

        if let exact = candidates.first(where: { $0.name == input }) {
            return exact.weekday
        }

        let fuzzyMatches =
            candidates
            .filter(\.allowsFuzzyMatching)
            .map { ($0.weekday, editDistance(input, $0.name), $0.name.count) }
            .filter { _, distance, length in distance <= (length >= 7 ? 2 : 1) }

        return fuzzyMatches.min {
            if $0.1 == $1.1 { return $0.2 < $1.2 }
            return $0.1 < $1.1
        }?.0
    }

    /// Case and accent folded, so a grammar word matches however the user typed it.
    static func normalizedParserWord(_ value: String) -> String {
        normalizedWord(value)
    }

    /// Time values are compared without the spacing and dots people vary on,
    /// so `9 p.m.` and `9pm` normalise to the same word.
    static func normalizedTimeValue(_ value: String) -> String {
        normalizedParserWord(value)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
    }

    static func isExcluded(_ range: NSRange, by excludedRanges: [NSRange]) -> Bool {
        excludedRanges.contains { NSIntersectionRange(range, $0).length > 0 }
    }
}

private func normalizedDateWord(_ value: String) -> String {
    normalizedWord(value).trimmingCharacters(in: CharacterSet.punctuationCharacters)
}

private func normalizedWord(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
}

private func localizedCalendar(_ calendar: Calendar, _ localeIdentifier: String) -> Calendar {
    var localizedCalendar = calendar
    localizedCalendar.locale = Locale(identifier: localeIdentifier)
    return localizedCalendar
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

private func editDistance(_ lhs: String, _ rhs: String) -> Int {
    let lhs = Array(lhs)
    let rhs = Array(rhs)
    var previous = Array(0...rhs.count)

    for (lhsIndex, lhsCharacter) in lhs.enumerated() {
        var current = [lhsIndex + 1]
        for (rhsIndex, rhsCharacter) in rhs.enumerated() {
            current.append(
                [
                    current[rhsIndex] + 1,
                    previous[rhsIndex + 1] + 1,
                    previous[rhsIndex] + (lhsCharacter == rhsCharacter ? 0 : 1),
                ].min()!)
        }
        previous = current
    }
    return previous[rhs.count]
}
