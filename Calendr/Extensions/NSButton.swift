//
//  NSButton.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa

extension NSButton {

    func setTitleColor(color: NSColor, font: NSFont) {
        let attrTitle = NSMutableAttributedString(string: title)
        let range = NSRange(location: 0, length: attributedTitle.length)

        attrTitle.addAttributes([
            .foregroundColor: color,
            .font: font.withSize(font.pointSize),
        ], range: range)

        attributedTitle = attrTitle
    }
}
