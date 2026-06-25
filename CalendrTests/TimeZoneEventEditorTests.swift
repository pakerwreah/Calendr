//
//  TimeZoneEventEditorTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation
import Testing
@testable import Calendr

class TimeZoneEventEditorTests {

    private let now = Date.make(year: 2026, month: 1, day: 1)
    private let daylight = Date.make(year: 2026, month: 8, day: 1)

    @Test func testDisplayName() {
        let newYork = TimeZone(identifier: "America/New_York")!
        let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!
        let vilnius = TimeZone(identifier: "Europe/Vilnius")!

        #expect(newYork.displayName(for: now) == "(GMT-05:00) America/New_York")
        #expect(saoPaulo.displayName(for: now) == "(GMT-03:00) America/Sao_Paulo")
        #expect(vilnius.displayName(for: now) == "(GMT+02:00) Europe/Vilnius")
    }

    @Test func testDisplayName_withDaylightSaving() {
        let newYork = TimeZone(identifier: "America/New_York")!
        let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!
        let vilnius = TimeZone(identifier: "Europe/Vilnius")!

        #expect(newYork.displayName(for: daylight) == "(GMT-04:00) America/New_York")
        #expect(saoPaulo.displayName(for: daylight) == "(GMT-03:00) America/Sao_Paulo")
        #expect(vilnius.displayName(for: daylight) == "(GMT+03:00) Europe/Vilnius")
    }

    @Test func testOptions_displayNamesAreUnique() {
        let displayNames = TimeZone.options(for: now).map { $0.displayName(for: now) }
        #expect(displayNames.count == Set(displayNames).count)
    }

    @Test func testOptions_isSorted() {
        let options = TimeZone.options(for: now)

        for index in options.indices.dropFirst() {
            let previous = options[index - 1]
            let current = options[index]
            let previousOffset = previous.secondsFromGMT(for: now)
            let currentOffset = current.secondsFromGMT(for: now)

            if previousOffset == currentOffset {
                #expect(previous.identifier.localizedCaseInsensitiveCompare(current.identifier) == .orderedAscending)
            } else {
                #expect(previousOffset < currentOffset)
            }
        }
    }
}
