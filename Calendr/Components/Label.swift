//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa

class Label: NSTextView {
    init(text: String = "") {
        super.init(frame: .zero, textContainer: NSTextView().textContainer)
        string = text
        isEditable = false
        drawsBackground = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
