//
//  Checkbox.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa

func Checkbox(title: String = "") -> NSButton {
    let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
    checkbox.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    checkbox.refusesFirstResponder = true
    return checkbox
}
