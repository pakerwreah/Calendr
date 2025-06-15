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

    private lazy var formatter = DateFormatter(template: "ddMMYYYY", calendar: dateProvider.calendar)

    init(appleScriptRunner: ScriptRunner, dateProvider: DateProviding) {
        self.appleScriptRunner = appleScriptRunner
        self.dateProvider = dateProvider
    }

    func openCalendar(at date: Date, mode: CalendarViewMode) async -> Bool {
        Popover.closeAll()
        do {
            try await appleScriptRunner.run("""
                    tell application "Calendar"
                    switch view to \(mode) view
                    delay 0.3
                    view calendar at date ("\(formatter.string(from: date))")
                    activate
                    end tell
                """)
            return true
        } catch {
            print("⚠️ Open Calendar script failed!")
            return false
        }
    }
}
