//
//  CursorButton.swift
//  Calendr
//
//  Created by Paker on 19/02/23.
//

import Cocoa

class CursorButton: NSButton {

    private var trackingArea: NSTrackingArea?
    private let cursor: NSCursor?

    init(cursor: NSCursor? = .pointingHand) {
        self.cursor = cursor
        super.init(frame: .zero)
        refusesFirstResponder = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 🔨 For some reason addCursorRect is not reliable,
    //    maybe because the container may clip the touch area and mess up
    //    the mouse enter detection, but to be honest I have no idea why
    override func updateTrackingAreas() {

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.cursorUpdate, .mouseMoved, .mouseEnteredAndExited, .activeAlways],
            owner: self
        )

        addTrackingArea(trackingArea!)

        super.updateTrackingAreas()
    }

    override func cursorUpdate(with event: NSEvent) {
        super.cursorUpdate(with: event)
        cursor?.set()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        cursorUpdate(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        super.cursorUpdate(with: event)
    }
}
