//
//  NSView.swift
//  Calendr
//
//  Created by Paker on 07/02/21.
//

import Cocoa

extension NSView {

    convenience init(wrapping: NSView) {
        self.init()
        addSubview(wrapping)
    }
}
