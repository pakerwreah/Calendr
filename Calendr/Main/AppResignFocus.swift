//
//  AppResignFocus.swift
//  Calendr
//
//  Created by Paker on 10/06/24.
//

import AppKit

extension AppDelegate {

    // 🔨 Fix desktop click when user disables:
    ///   System Settings > Desktop & Dock > Desktop & Stage Manager > Show Items > On Desktop
    func setUpResignFocus() {

        NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown],
            handler: resignFocus
        )
    }

    private func resignFocus(event: NSEvent) {
        guard
            NSApp.keyWindow != nil,
            isDesktop(event.windowNumber)
        else { return }

        for window in NSApp.windows {
            window.resignKey()
        }
    }

    private func isDesktop(_ windowNumber: Int) -> Bool {
        guard
            let infoList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as NSArray?
        else { return false }

        return infoList.contains(where: {
            guard
                let info = $0 as? NSDictionary,
                info[kCGWindowNumber as String] as? Int == windowNumber,
                info[kCGWindowOwnerName as String] as? String == "WindowManager"
            else {
                return false
            }

            return true
        })
    }
}
