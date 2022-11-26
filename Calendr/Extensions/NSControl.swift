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

    func focus() {
        let oldValue = refusesFirstResponder
        refusesFirstResponder = false
        becomeFirstResponder()
        refusesFirstResponder = oldValue
    }

    func blur() {
        resignFirstResponder()
    }
}
