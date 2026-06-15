//
//  TimeZone+EventEditor.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation

extension TimeZone {

    static func options(for date: Date) -> [TimeZone] {
        return TimeZone.knownTimeZoneIdentifiers
            .compactMap(TimeZone.init(identifier:))
            .sorted {
                let offset0 = $0.secondsFromGMT(for: date)
                let offset1 = $1.secondsFromGMT(for: date)
                if offset0 != offset1 { return offset0 < offset1 }
                return $0.identifier.localizedCaseInsensitiveCompare($1.identifier) == .orderedAscending
            }
    }

    func gmtDisplayString(for date: Date) -> String {
        let offsetInSeconds = secondsFromGMT(for: date)

        let totalMinutes = abs(offsetInSeconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = offsetInSeconds >= 0 ? "+" : "-"

        return String(format: "GMT%@%02d:%02d", sign, hours, minutes)
    }

    func displayName(for date: Date) -> String {
        "(\(gmtDisplayString(for: date))) \(identifier)"
    }
}
