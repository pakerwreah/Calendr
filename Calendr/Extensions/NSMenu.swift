//
//  NSMenu.swift
//  Calendr
//
//  Created by Paker on 21/07/24.
//

import AppKit

private var activeMenus: [NSMenu] = []

class NSMenu: AppKit.NSMenu {

    @discardableResult
    override func popUp(positioning item: NSMenuItem?, at location: NSPoint, in view: NSView?) -> Bool {
        activeMenus.append(self)
        let result = super.popUp(positioning: item, at: location, in: view)
        activeMenus.removeAll { $0 == self }
        return result
    }

    static func closeAll() {
        for menu in activeMenus {
            menu.cancelTracking()
        }
    }
}
