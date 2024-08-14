//
//  TrackedMenu.swift
//  Calendr
//
//  Created by Paker on 15/08/24.
//

import AppKit

private var closeAllCallbacks: [() -> Void] = []

private var activeMenus: [TrackedMenu] = [] {
    didSet {
        guard activeMenus.isEmpty else { return }

        for callback in closeAllCallbacks {
            callback()
        }
        closeAllCallbacks.removeAll()
    }
}

class TrackedMenu: NSMenu, NSMenuDelegate {

    init() {
        super.init(title: "")
        delegate = self
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        activeMenus.append(self)
    }

    func menuDidClose(_ menu: NSMenu) {
        activeMenus.removeAll { $0 == self }
    }

    @discardableResult
    override func popUp(positioning item: NSMenuItem?, at location: NSPoint, in view: NSView?) -> Bool {
        blocking {
            super.popUp(positioning: item, at: location, in: view)
        }
    }

    static func closeAll(completion: (() -> Void)?) {
        guard !activeMenus.isEmpty else {
            completion?()
            return
        }
        if let completion {
            closeAllCallbacks.append(completion)
        }
        for menu in activeMenus {
            menu.cancelTracking()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
