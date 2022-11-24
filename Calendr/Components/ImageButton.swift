//
//  ImageButton.swift
//  Calendr
//
//  Created by Paker on 24/11/2022.
//

import Cocoa

class ImageButton: NSButton {

    private var trackingArea: NSTrackingArea?

    init() {
        super.init(frame: .zero)

        isBordered = false
        bezelStyle = .roundRect
        refusesFirstResponder = true
        showsBorderOnlyWhileMouseInside = true // this actually controls highlight ¯\_(ツ)_/¯
        setContentCompressionResistancePriority(.required, for: .horizontal)
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
            options: [.cursorUpdate, .mouseMoved, .activeAlways],
            owner: self
        )

        addTrackingArea(trackingArea!)

        super.updateTrackingAreas()
    }

    override func cursorUpdate(with event: NSEvent) {
        super.cursorUpdate(with: event)
        NSCursor.pointingHand.set()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        cursorUpdate(with: event)
    }
}
