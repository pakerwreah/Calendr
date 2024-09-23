//
//  NSImageView.swift
//  Calendr
//
//  Created by Paker on 23/09/2024.
//

import Cocoa

extension NSImageView {

    func with(color: NSColor) -> Self {
        contentTintColor = color
        return self
    }
}
