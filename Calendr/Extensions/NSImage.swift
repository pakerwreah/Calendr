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

    func with(pointSize: CGFloat, weight: NSFont.Weight = .medium) -> NSImage {
        withSymbolConfiguration(.init(pointSize: pointSize, weight: weight))!
    }

    func with(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        NSRect(origin: .zero, size: image.size).fill(using: .sourceIn)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
