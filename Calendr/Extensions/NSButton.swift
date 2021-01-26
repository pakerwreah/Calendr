//
//  NSButton.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa

extension NSButton {

    func setTitleColor(color: NSColor?) {
        let newAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
        let range = NSRange(location: 0, length: attributedTitle.length)

        newAttributedTitle.removeAttribute(.foregroundColor, range: range)

        if let color = color {
            newAttributedTitle.addAttribute(.foregroundColor, value: color, range: range)
        }

        attributedTitle = newAttributedTitle
    }
}
