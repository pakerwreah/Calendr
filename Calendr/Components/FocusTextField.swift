//
//  FocusTextField.swift
//  Calendr
//
//  Created by Paker on 26/09/2026.
//

import SwiftUI

class FocusTextField: NSTextField {

    @Binding private var focus: Bool

    init(focus: Binding<Bool>) {
        _focus = focus
        super.init(frame: .zero)
    }

    // textDidBeginEditing only triggers after a key press
    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became {
            focus = true
        }
        return became
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        focus = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
