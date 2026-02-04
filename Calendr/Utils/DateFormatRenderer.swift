//
//  DateFormatRenderer.swift
//  Calendr
//
//  Created by Paker on 04/02/26.
//

import Foundation

enum DateFormatRenderer {

    private static let timeZoneTokenRegex = try? NSRegularExpression(
        pattern: #"([^\s]+)@(GMT[+-]\d{1,2}(?::\d{2})?)"#,
        options: []
    )

    static func render(format: String, date: Date, calendar: Calendar) -> String {
        let processedFormat = replaceTimeZoneTokens(in: format, date: date, calendar: calendar)
        let formatter = DateFormatter(format: processedFormat, calendar: calendar)
        return formatter.string(from: date)
    }

    // Replaces `format@GMT±H` tokens with literal formatted values so a single format can render multiple timezones.
    private static func replaceTimeZoneTokens(in format: String, date: Date, calendar: Calendar) -> String {
        guard
            format.contains("@GMT"),
            let timeZoneTokenRegex
        else {
            return format
        }

        let matches = timeZoneTokenRegex.matches(
            in: format,
            range: NSRange(format.startIndex..., in: format)
        )
        guard !matches.isEmpty else { return format }

        var updatedFormat = format

        for match in matches.reversed() {
            guard
                let fullRange = Range(match.range, in: updatedFormat),
                let formatRange = Range(match.range(at: 1), in: updatedFormat),
                let timeZoneRange = Range(match.range(at: 2), in: updatedFormat)
            else {
                continue
            }

            let formatToken = String(updatedFormat[formatRange])
            let timeZoneToken = String(updatedFormat[timeZoneRange])

            guard let timeZone = timeZone(fromGMTToken: timeZoneToken) else { continue }

            let formatter = DateFormatter(calendar: calendar)
            formatter.timeZone = timeZone
            formatter.dateFormat = formatToken
            let formattedValue = formatter.string(from: date)

            var replacementRange = fullRange
            var replacementValue = formattedValue

            if let literal = followingLiteral(in: updatedFormat, from: fullRange.upperBound) {
                replacementRange = fullRange.lowerBound..<literal.range.upperBound
                replacementValue += literal.value
            }

            updatedFormat.replaceSubrange(replacementRange, with: literalDateFormat(for: replacementValue))
        }

        return updatedFormat
    }

    private static func timeZone(fromGMTToken value: String) -> TimeZone? {
        let prefix = "GMT"
        guard value.hasPrefix(prefix) else { return nil }

        let signIndex = value.index(value.startIndex, offsetBy: prefix.count)
        guard signIndex < value.endIndex else { return nil }

        let sign = value[signIndex]
        let offsetStart = value.index(after: signIndex)
        let offsetText = String(value[offsetStart...])

        // Parse offset as H:MM or H
        let components = offsetText.split(separator: ":")
        guard let hours = Int(components[0]) else { return nil }
        let minutes = components.count == 2 ? Int(components[1]) : 0
        
        guard let minutes = minutes else { return nil }
        guard (0...14).contains(hours) else { return nil }
        guard (0...59).contains(minutes) else { return nil }

        let multiplier: Int
        switch sign {
        case "+":
            multiplier = 1
        case "-":
            multiplier = -1
        default:
            return nil
        }

        let offsetSeconds = (hours * 3600 + minutes * 60) * multiplier
        return TimeZone(secondsFromGMT: offsetSeconds)
    }

    private static func literalDateFormat(for value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "''")
        return "'\(escaped)'"
    }

    // If a quoted literal immediately follows, merge it to avoid `''` producing a literal quote.
    private static func followingLiteral(
        in format: String,
        from index: String.Index
    ) -> (range: Range<String.Index>, value: String)? {
        guard index < format.endIndex, format[index] == "'" else { return nil }

        var currentIndex = format.index(after: index)
        var value = ""

        while currentIndex < format.endIndex {
            let character = format[currentIndex]

            if character == "'" {
                let nextIndex = format.index(after: currentIndex)
                if nextIndex < format.endIndex, format[nextIndex] == "'" {
                    value.append("'")
                    currentIndex = format.index(after: nextIndex)
                    continue
                }

                let range = index..<format.index(after: currentIndex)
                return (range, value)
            }

            value.append(character)
            currentIndex = format.index(after: currentIndex)
        }

        return nil
    }
}
