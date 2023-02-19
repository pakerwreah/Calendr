//
//  Checkbox.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa

class Checkbox: CursorButton {

    init(title: String = "", cursor: NSCursor? = .pointingHand) {
        super.init(cursor: cursor)

        self.title = title
        setButtonType(.switch)
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
