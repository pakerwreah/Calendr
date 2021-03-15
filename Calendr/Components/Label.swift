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

    var isEmpty: Bool {
        stringValue.isEmpty && attributedStringValue.length == 0
    }

    convenience init() {
        self.init(text: "")
    }

    convenience init(text: String = "", font: NSFont? = nil, color: NSColor? = nil, align: NSTextAlignment = .left) {
        self.init(labelWithString: text)
        self.font = font
        self.textColor = color
        self.alignment = align
        setUpLayout()
    }

    convenience init(text: NSAttributedString) {
        self.init(labelWithAttributedString: text)
        setUpLayout()
    }

    private func setUpLayout() {
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    }
}
