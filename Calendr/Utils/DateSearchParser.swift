//
//  DateSearchParser.swift
//  Calendr
//
//  Created by Paker on 18/12/2024.
//

import Foundation

typealias DateSuggestionResult = (date: Date, result: String)

private typealias DateSuggestionMatch = (date: Date, range: Range<String.Index>)

enum DateSearchParser {

    static func parse(text: String, using dateProvider: DateProviding) -> DateSuggestionResult? {

        let formatter = DateFormatter(calendar: dateProvider.calendar)

        if let match = searchMatchDate(text: text) {
            return makeResult(text, match)
        }

        if let match = searchMatchMonth(text: text, symbols: formatter.monthSymbols, dateProvider: dateProvider) {
            return makeResult(text, match)
        }

        if let match = searchMatchMonth(text: text, symbols: formatter.shortMonthSymbols, dateProvider: dateProvider) {
            return makeResult(text, match)
        }

        return nil
    }
}

private func makeResult(_ text: String, _ match: DateSuggestionMatch) -> DateSuggestionResult {
    var result = text
    result.removeSubrange(match.range)
    return (match.date, result.trimmingCharacters(in: .whitespaces))
}

private func searchMatchDate(text: String) -> DateSuggestionMatch? {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
    guard
        let match = matches?.first(where: \.date.isNotNil),
        let date = match.date,
        let range = Range(match.range, in: text)
    else {
        return nil
    }
    return (date, range)
}

private func isSeparator(_ character: Character) -> Bool {
    !character.isLetter && !character.isNumber
}

private func searchMatchMonth(text: String, symbols: [String], dateProvider: DateProviding) -> DateSuggestionMatch? {
    var components = dateProvider.calendar.dateComponents([.year, .month, .day], from: dateProvider.now)

    for (index, month) in symbols.enumerated() {
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: month, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
            // ensure the found range is not part of a larger word
            guard
                (range.lowerBound == text.startIndex || isSeparator(text[text.index(before: range.lowerBound)])),
                (range.upperBound == text.endIndex || isSeparator(text[range.upperBound]))
            else {
                searchRange = range.upperBound..<text.endIndex
                continue
            }

            components.month = index + 1

            // extract year if it exists after the month
            var extendedRange = range
            if let yearRange = text[range.upperBound...].range(of: #"(\d{4})"#, options: .regularExpression) {
                if let yearStr = Int(text[yearRange].trimmingCharacters(in: .whitespaces)) {
                    components.year = yearStr
                    // Extend the range to include the year
                    extendedRange = range.lowerBound..<yearRange.upperBound
                }
            }

            // create the date from components
            if let date = dateProvider.calendar.date(from: components) {
                return (date, extendedRange)
            }

            // if for some reason we can't create the date from components
            // update search range and continue searching for further instances
            searchRange = range.upperBound..<text.endIndex
        }
    }

    return nil
}
