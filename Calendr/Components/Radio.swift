//
//  Radio.swift
//  Calendr
//
//  Created by Paker on 30/01/21.
//

import Cocoa

func Radio(title: String = "") -> NSButton {
    let radio = NSButton(radioButtonWithTitle: title, target: nil, action: nil)
    radio.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    radio.refusesFirstResponder = true
    return radio
}
