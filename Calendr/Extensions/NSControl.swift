//
//  NSControl.swift
//  Calendr
//
//  Created by Paker on 26/11/2022.
//

import Cocoa

extension NSControl {

    var hasFocus: Bool {
        get { currentEditor() != nil }
        set { newValue ? focus() : blur() }
    }

    func focus(force: Bool = true) {
        guard refusesFirstResponder, force else {
            window?.makeFirstResponder(self)
            return
        }
        refusesFirstResponder = false
        window?.makeFirstResponder(self)
        refusesFirstResponder = true
    }

    func blur() {
        if hasFocus {
            window?.makeFirstResponder(nil)
        }
    }
}
