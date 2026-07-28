//
//  EventSearch.swift
//  Calendr
//
//  Created by Paker on 28/07/2026.
//

import Foundation

enum EventSearch {

    static func search(_ searchTerm: String, in event: EventModel) -> Bool {

        let (searchTags, searchTerm) = extractTags(from: searchTerm.trimmed)

        guard searchTags.isEmpty || searchTags.isSubset(of: event.tags, options: .caseInsensitive) else {
            return false
        }

        guard !searchTerm.isEmpty else { return true }

        return [
            event.title,
            event.location,
            event.url?.absoluteString,
            event.notes,
            event.participants.map(\.name).joined(separator: " ")
        ]
        .contains {
            $0?.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}

private func extractTags(from searchTerm: String) -> (searchTags: [String], searchTerm: String) {

    guard searchTerm.contains("#") else { return ([], searchTerm) }

    let parts = searchTerm.split(separator: " ").map(String.init)

    var hashtags: [String] = []
    var rest: String = ""

    for p in parts {
        if p.hasPrefix("#") {
            hashtags.append(String(p.dropFirst(1)))
        } else {
            if !rest.isEmpty {
                rest.append(" ")
            }
            rest.append(p)
        }
    }

    return (hashtags, rest)
}

private extension Collection where Element: StringProtocol {

    func isSubset(of other: Self, options: String.CompareOptions = []) -> Bool {
        allSatisfy { searchTag in
            other.contains { $0.compare(searchTag, options: options) == .orderedSame }
        }
    }
}
