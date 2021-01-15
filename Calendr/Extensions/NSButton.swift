//
//  NSButton.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa

extension NSButton {

    func setTitleColor(color: NSColor) {
        let newAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
        let range = NSRange(location: 0, length: attributedTitle.length)

        newAttributedTitle.addAttributes([
            .foregroundColor: color,
        ], range: range)

        attributedTitle = newAttributedTitle
    }
}
