//
//  NSButton.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa

extension NSButton {

    func setTitleColor(color: NSColor, font: NSFont) {

        attributedTitle = .init(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: font
            ]
        )
    }
}
