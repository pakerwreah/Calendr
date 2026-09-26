//
//  EventTitleParser+Universal.swift
//  Calendr
//
//  Created by Paker on 25/09/2026.
//

import Foundation
import NaturalLanguage
import DataDetection

private enum CalendarEventDetector {

    struct MatchResult {
        let range: NSRange
        let date: Date?
        let duration: TimeInterval
        let allDay: Bool
    }

    static func matches(
        in text: String,
        calendar: Calendar,
        referenceDate: Date
    ) async -> [MatchResult] {

        if #available(macOS 26.0, *) {
            await matches26(in: text, calendar: calendar, referenceDate: referenceDate)
        } else {
            matches15(in: text)
        }
    }

    @available(macOS 26.0, *)
    static func matches26(
        in text: String,
        calendar: Calendar,
        referenceDate: Date
    ) async -> [MatchResult] {

        var results: [MatchResult] = []

        var options = DataDetector.Options()
        options.documentDate = referenceDate
        options.documentTimeZone = calendar.timeZone
        let matches = text.dataDetectorMatches(.calendarEvent, options: options)

        for await match in matches {
            guard let range = match.range, case .calendarEvent(let details) = match.details else { continue }

            let duration: TimeInterval

            if let starDate = details.startDate, let endDate = details.endDate {
                duration = starDate.distance(to: endDate)
            } else {
                duration = 0
            }

            results.append(
                MatchResult(
                    range: NSRange(range, in: text),
                    date: details.startDate,
                    duration: duration,
                    allDay: details.allDay
                )
            )
        }

        return results
    }

    static func matches15(in text: String) -> [MatchResult] {

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }

        let matches = detector.matches(in: text, range: text.nsRange)

        return matches.map {
            MatchResult(
                range: $0.range,
                date: $0.date,
                duration: $0.duration,
                allDay: false
            )
        }
    }
}

enum UniversalEventTitleParser: EventTitleParsing {

    static func instructions(
        in originalText: String,
        calendar: Calendar,
        referenceDate: Date,
        excluding excludedRanges: [NSRange],
        firstWordRange: NSRange?
    ) async -> EventTitleInstructions {

        var instructions = EventTitleInstructions()

        let text = String(
            originalText.removingSubranges(
                RangeSet(excludedRanges.compactMap { Range($0, in: originalText) })
            )
        )

        let matches = await CalendarEventDetector.matches(
            in: text,
            calendar: calendar,
            referenceDate: referenceDate
        )

        let tokenizer = NLTokenizer(unit: .word)

        let globalOffset = firstWordRange?.length ?? 0

        for match in matches {
            guard
                let matchDate = match.date,
                let matchRangeInText = Range(match.range, in: text)
            else { continue }

            let components = calendar.dateComponents(in: calendar.timeZone, from: matchDate)

            let dateText = String(text[matchRangeInText])

            tokenizer.string = dateText

            /**
             * NOTE:
             *  NSDataDetector is very greedy and tends to group terms together like "dinner tomorrow"
             *  as being a temporal term, which is not really what we want, but it's better than nothing.
             *
             * To mitigate that we have to run a tokenizer and check individual terms.
             */
            for tokenRange in tokenizer.tokens(for: dateText.range) {

                let subTokenStr = String(dateText[tokenRange])

                let globalNSRange = translateRange(
                    tokenRange,
                    from: dateText,
                    offsetBy: globalOffset + match.range.location
                )

                if match.allDay {
                    instructions.allDayRanges.append(globalNSRange)
                }

                if let assignedType = evaluateAgnosticType(
                    tokenStr: subTokenStr,
                    components: components,
                    matchDate: matchDate,
                    matchDuration: match.duration,
                    referenceDate: referenceDate,
                    calendar: calendar
                ) {
                    switch assignedType {
                        case let .relativeDate(dayOffset, weekday):
                            var titleWeekday: EventTitleWeekday? = nil

                            if let weekday = weekday {
                                var occurrence: EventTitleWeekdayOccurrence = .nearest

                                // e.g. "next Friday"
                                if let offset = dayOffset, offset >= 7 {
                                    occurrence = .following
                                }

                                titleWeekday = EventTitleWeekday(
                                    weekday: weekday,
                                    occurrence: occurrence
                                )
                            }

                            let time = components.hour.map {
                                EventTitleTime(hour: $0, minute: components.minute ?? 0)
                            }

                            let dateMatch = EventTitleDateMatch(
                                dayOffset: dayOffset,
                                time: time,
                                numericDate: nil,
                                weekday: titleWeekday
                            )

                            insert(dateMatch, with: globalNSRange, into: &instructions.dates)

                        case let .startTime(hour, minute, durationWindow):
                            var endTime: EventTitleTime? = nil
                            if let durationWindow,
                               let baseDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: referenceDate),
                               let calculatedEnd = calendar.date(byAdding: .second, value: Int(durationWindow), to: baseDate) {
                                let endComps = calendar.dateComponents([.hour, .minute], from: calculatedEnd)
                                if let endH = endComps.hour, let endM = endComps.minute {
                                    endTime = EventTitleTime(hour: endH, minute: endM)
                                }
                            }

                            let time = EventTitleTime(hour: hour, minute: minute)
                            let timeMatch = EventTitleTimeMatch(time: time, endTime: endTime)

                            insert(timeMatch, with: globalNSRange, into: &instructions.times)
                    }
                }
            }
        }

        return instructions
    }
}

private func insert<Info: Equatable>(
    _ info: Info,
    with range: NSRange,
    into items: inout [EventTitleInstructions.Item<Info>]
) {
    let existingIndex = items.map(\.info).firstIndex(of: info)

    let instructionRange = if let existingIndex {
        NSUnionRange(items.remove(at: existingIndex).range, range)
    } else {
        range
    }

    items.append(.init(range: instructionRange, info: info))
}

private enum AgnosticTemporalType {
    case relativeDate(dayOffset: Int?, weekday: Int?)
    case startTime(hour: Int, minute: Int, duration: TimeInterval?)
}

private func evaluateAgnosticType(
    tokenStr: String,
    components: DateComponents,
    matchDate: Date,
    matchDuration: TimeInterval,
    referenceDate: Date,
    calendar: Calendar
) -> AgnosticTemporalType? {

    let cleanedToken = tokenStr.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedToken.isEmpty else { return nil }

    let isNumeric = cleanedToken.rangeOfCharacter(from: .decimalDigits) != nil

    // Scenario A: Precise Clock Extraction (Hours / Minutes)
    if isNumeric, let hour = components.hour {
        let minute = components.minute ?? 0
        let totalDuration = matchDuration > 0 ? matchDuration : nil
        return .startTime(hour: hour, minute: minute, duration: totalDuration)
    }

    let definesDateOffset = components.day != nil || components.weekday != nil

    // Scenario B: Relative Day & Weekday Offsets
    if !isNumeric && definesDateOffset {
        var calculatedOffset: Int? = nil
        var weekdayTarget: Int? = nil

        let today = calendar.startOfDay(for: referenceDate)
        let targetDay = calendar.startOfDay(for: matchDate)
        calculatedOffset = calendar.dateComponents([.day], from: today, to: targetDay).day

        if let systemWeekday = components.weekday {
            weekdayTarget = systemWeekday
        }

        return .relativeDate(dayOffset: calculatedOffset, weekday: weekdayTarget)
    }

    return nil
}

private func translateRange(_ substringRange: Range<String.Index>, from originalString: String, offsetBy baseOffset: Int) -> NSRange {
    let nsRange = NSRange(substringRange, in: originalString)
    return NSRange(location: nsRange.location + baseOffset, length: nsRange.length)
}
