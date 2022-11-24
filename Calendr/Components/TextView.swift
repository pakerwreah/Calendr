//
//  TextView.swift
//  Calendr
//
//  Created by Paker on 24/11/2022.
//

import Cocoa

class TextView: NSTextView {

    override var acceptsFirstResponder: Bool { isEditable }
}
