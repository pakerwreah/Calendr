//
//  NSView+Image.swift
//  Calendr
//
//  Created by Paker on 03/11/2025.
//

import AppKit

extension NSView {

    func asImage(appearance: NSAppearance? = nil) -> NSImage? {
        layoutSubtreeIfNeeded()

        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }

        performWithAppearance(appearance) {
            cacheDisplay(in: bounds, to: rep)
        }

        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)

        return image
    }

    private func performWithAppearance(_ appearance: NSAppearance?, task: () -> Void) {
        guard let appearance else {
            return task()
        }
        let previous = self.appearance
        self.appearance = appearance
        task()
        self.appearance = previous
    }
}
