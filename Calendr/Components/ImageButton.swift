//
//  ImageButton.swift
//  Calendr
//
//  Created by Paker on 24/11/2022.
//

import Cocoa

class ImageButton: CursorButton {

    init(image: NSImage? = nil, cursor: NSCursor? = .pointingHand) {
        super.init(cursor: cursor)
        self.image = image

        isBordered = false
        bezelStyle = .roundRect
        showsBorderOnlyWhileMouseInside = true // this actually controls highlight ¯\_(ツ)_/¯
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
