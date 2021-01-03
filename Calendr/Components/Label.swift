//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa

class Label: NSTextView {
    override var string: String {
        didSet {
            needsDisplay = true
        }
    }

    init(text: String = "") {
        super.init(frame: .zero, textContainer: NSTextView().textContainer)
        string = text
        isEditable = false
        drawsBackground = false
        backgroundColor = .clear
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil // prevents click and helps prevent cursor change
    }

    override func mouseMoved(with event: NSEvent) {
        // prevents changing cursor
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: (font?.pointSize ?? 0) + 4)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
