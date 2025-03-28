//
//  CalendarScript.swift
//  Calendr
//
//  Created by Paker on 26/02/23.
//

import Foundation

class CalendarScript {

    private let workspace: WorkspaceServiceProviding
    private let formatter = DateFormatter().with(style: .full)

    init(workspace: WorkspaceServiceProviding) {
        self.workspace = workspace
    }

    func openCalendar(at date: Date, mode: CalendarViewMode) {
        Popover.closeAll()
        Task {
            do {
                try await runScript("""
                    tell application "Calendar"
                    switch view to \(mode) view
                    delay 0.3
                    view calendar at date ("\(formatter.string(from: date))")
                    
                    activate
                    end tell
                """)
            } catch {
                print("⚠️ Open Calendar script failed! Falling back to workspace open.")
                if let appUrl = workspace.urlForApplication(toOpen: URL(string: "webcal://")!) {
                    workspace.open(appUrl)
                }
            }
        }
    }
}
