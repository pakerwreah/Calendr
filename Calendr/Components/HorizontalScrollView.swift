//
//  HorizontalScrollView.swift
//  Calendr
//
//  Created by Paker on 08/09/2024.
//

import AppKit

class HorizontalScrollView: NSScrollView {

    override func scrollWheel(with event: NSEvent) {
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY

        guard abs(deltaX) == 0 else {
            super.scrollWheel(with: event)
            return
        }

        let newOriginX = contentView.bounds.origin.x - deltaY
        let constrainedOriginX = max(min(newOriginX, documentView!.bounds.width - contentView.bounds.width), 0)

        contentView.setBoundsOrigin(NSPoint(x: constrainedOriginX, y: contentView.bounds.origin.y))
    }
}
