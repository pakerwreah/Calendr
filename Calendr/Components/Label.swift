//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa

class Label: NSTextField {

    var forceVibrancy: Bool?

    override var allowsVibrancy: Bool {
        forceVibrancy ?? super.allowsVibrancy
    }

    convenience init() {
        self.init(text: "")
    }

    convenience init(text: String = "", font: NSFont? = nil) {
        self.init(labelWithString: text)
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        self.font = font
    }
}
