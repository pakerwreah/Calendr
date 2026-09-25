//
//  EventTitleParser+Universal.swift
//  Calendr
//

import Foundation
import NaturalLanguage

enum UniversalEventTitleParser: EventTitleParsing {

    static func instructions(
        in text: String,
        dateProvider: DateProviding,
        calendar: Calendar,
        excluding excludedRanges: [NSRange]
    ) -> EventTitleInstructions {

        var instructions = EventTitleInstructions()

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return instructions
        }

        let referenceDate = dateProvider.now

        let matches = detector.matches(in: text, range: text.nsRange)

        for match in matches {
            let components = match.date?.components(using: dateProvider, calendar: calendar.identifier)

            let dateText = String(text[Range(match.range, in: text)!])
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.string = dateText

            //
            // NSDataDetector is very greedy and tends to group terms together like "dinner tomorrow"
            // as being a temporal token, which is not really what we want.
            //
            // To fix that we have to run a tokenizer and check individual terms.
            //
            // FIXME: This is not working. It still detects "dinner" / "lunch" as a date token 😔
            //
            tokenizer.enumerateTokens(in: dateText.range) { tokenRange, _ in
                let subTokenStr = String(dateText[tokenRange])
                let globalNSRange = translateRange(tokenRange, from: dateText, offsetBy: match.range.location)

                // This helps ignoring "dinner" / "lunch" at the beginning, but I'd rather not rely on this
                guard !isExcluded(globalNSRange, by: excludedRanges) else { return true }

                // 3. Evaluate type structural signals completely without string matching
                if let assignedType = evaluateAgnosticType(
                    tokenStr: subTokenStr,
                    components: components,
                    tokenRange: tokenRange,
                    dateText: dateText,
                    match: match,
                    referenceDate: referenceDate,
                    calendar: calendar
                ) {
                    switch assignedType {
                        case let .relativeDate(dayOffset, weekday):
                            var titleWeekday: EventTitleWeekday? = nil

                            if let weekday = weekday {
                                // Default to nearest occurrence
                                var occurrence: EventTitleWeekdayOccurrence = .nearest

                                // If the system's calculated day gap spans a week or more,
                                // it structurally flags a "following" layout indicator (e.g., "next Friday")
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
    components: DateComponents?,
    tokenRange: Range<String.Index>,
    dateText: String,
    match: NSTextCheckingResult,
    referenceDate: Date,
    calendar: Calendar
) -> AgnosticTemporalType? {

    let cleanedToken = tokenStr.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedToken.isEmpty else { return nil }

    let isNumeric = cleanedToken.rangeOfCharacter(from: .decimalDigits) != nil

    if let components {
        let today = calendar.startOfDay(for: referenceDate)

        // Scenario A: Precise Clock Extraction (Hours / Minutes)
        if let hour = components.hour {
            let minute = components.minute ?? 0

            if isNumeric || cleanedToken.count <= 4 {
                let totalDuration = match.duration > 0 ? match.duration : nil
                return .startTime(hour: hour, minute: minute, duration: totalDuration)
            }
        }

        let definesDateOffset = components.day != nil || components.weekday != nil

        // Scenario B: Relative Day & Weekday Offsets
        if !isNumeric && definesDateOffset {
            var calculatedOffset: Int? = nil
            var weekdayTarget: Int? = nil

            if let absoluteTargetDate = match.date {
                let targetDay = calendar.startOfDay(for: absoluteTargetDate)
                calculatedOffset = calendar.dateComponents([.day], from: today, to: targetDay).day
            }

            if let systemWeekday = components.weekday {
                weekdayTarget = systemWeekday
            }

            return .relativeDate(dayOffset: calculatedOffset, weekday: weekdayTarget)
        }
    }

    return nil
}

private func translateRange(_ substringRange: Range<String.Index>, from originalString: String, offsetBy baseOffset: Int) -> NSRange {
    let nsRange = NSRange(substringRange, in: originalString)
    return NSRange(location: nsRange.location + baseOffset, length: nsRange.length)
}
