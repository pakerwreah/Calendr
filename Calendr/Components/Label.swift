//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa

func Label(text: String = "", font: NSFont? = nil) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = font
    return label
}
