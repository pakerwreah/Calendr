//
//  EventTitleParser+Universal.swift
//  Calendr
//
//  Created by Paker on 25/09/2026.
//

import Foundation
import NaturalLanguage

enum UniversalEventTitleParser: EventTitleParsing {

    static func instructions(
        in text: String,
        calendar: Calendar,
        referenceDate: Date,
        excluding excludedRanges: [NSRange]
    ) -> EventTitleInstructions {

        var instructions = EventTitleInstructions()

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return instructions
        }

        let matches = detector.matches(in: text, range: text.nsRange)

        let tokenizer = NLTokenizer(unit: .word)

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
             * That way we can at least filter out excluded ranges from the start/end.
             */
            tokenizer.enumerateTokens(in: dateText.range) { tokenRange, _ in
                let subTokenStr = String(dateText[tokenRange])
                let globalNSRange = translateRange(tokenRange, from: dateText, offsetBy: match.range.location)

                // This helps ignoring "dinner" / "lunch" at the beginning
                guard !isExcluded(globalNSRange, by: excludedRanges) else { return true }

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

                            let existingIndex = instructions.dates.firstIndex {
                                $0.dayOffset == dayOffset && $0.weekday == titleWeekday
                            }

                            let instructionRange = if let existingIndex {
                                NSUnionRange(instructions.dates.remove(at: existingIndex).range, globalNSRange)
                            } else {
                                globalNSRange
                            }

                            instructions.dates.append(
                                EventTitleDateMatch(
                                    range: instructionRange,
                                    dayOffset: dayOffset,
                                    numericDate: nil,
                                    weekday: titleWeekday
                                )
                            )

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

                            let existingIndex = instructions.times.firstIndex {
                                $0.time == time && $0.endTime == endTime
                            }

                            let instructionRange = if let existingIndex {
                                NSUnionRange(instructions.times.remove(at: existingIndex).range, globalNSRange)
                            } else {
                                globalNSRange
                            }

                            instructions.times.append(
                                EventTitleTimeMatch(
                                    range: instructionRange,
                                    time: time,
                                    endTime: endTime
                                )
                            )
                    }
                }
                return true
            }
        }

        return instructions
    }
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
    if let hour = components.hour {
        let minute = components.minute ?? 0

        if isNumeric || cleanedToken.count <= 4 {
            let totalDuration = matchDuration > 0 ? matchDuration : nil
            return .startTime(hour: hour, minute: minute, duration: totalDuration)
        }
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
