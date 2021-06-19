//
//  NSImage.swift
//  Calendr
//
//  Created by Paker on 19/06/2021.
//

import AppKit

extension NSImage {

    convenience init(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)!
    }

    func with(scale: NSImage.SymbolScale) -> NSImage { withSymbolConfiguration(.init(scale: scale))! }

    func with(size: CGFloat, weight: NSFont.Weight = .medium) -> NSImage {
        withSymbolConfiguration(.init(pointSize: size, weight: weight))!
    }
}
