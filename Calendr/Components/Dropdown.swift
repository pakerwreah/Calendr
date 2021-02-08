//
//  Dropdown.swift
//  Calendr
//
//  Created by Paker on 07/02/21.
//

import Cocoa

func Dropdown() -> NSPopUpButton {
    let dropdown = NSPopUpButton()
    dropdown.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    dropdown.refusesFirstResponder = true
    return dropdown
}
