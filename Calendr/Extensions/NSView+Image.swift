//
//  NSView+Image.swift
//  Calendr
//
//  Created by Paker on 03/11/2025.
//

import AppKit

extension NSView {
    
    func asImage() -> NSImage? {
        layoutSubtreeIfNeeded()
        
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        
        return image
    }
}
