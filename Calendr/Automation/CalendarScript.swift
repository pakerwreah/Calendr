//
//  CalendarScript.swift
//  Calendr
//
//  Created by Paker on 26/02/23.
//

import Foundation

class CalendarScript {

    private let appleScriptRunner: ScriptRunner
    private let dateProvider: DateProviding

    init(appleScriptRunner: ScriptRunner, dateProvider: DateProviding) {
        self.appleScriptRunner = appleScriptRunner
        self.dateProvider = dateProvider
    }

    func openCalendar(at date: Date, mode: CalendarViewMode) async -> Bool {
        Popover.closeAll()
        do {
            let c = dateProvider.calendar.dateComponents([.day, .month, .year], from: date)

            try await appleScriptRunner.run("""
                    set theDate to current date
                    set day of theDate to \(c.day!)
                    set month of theDate to \(c.month!)
                    set year of theDate to \(c.year!)
                    tell application "Calendar"
                    switch view to \(mode) view
                    delay 0.3
                    view calendar at theDate
                    activate
                    end tell
                """)
            return true
        } catch {
            print("⚠️ Open Calendar script failed!", error.localizedDescription, separator: "\n")
            return false
        }
    }
}
