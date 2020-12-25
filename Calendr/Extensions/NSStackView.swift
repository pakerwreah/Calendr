//
//  NSStackView.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa

extension NSStackView {
    convenience init(_ orientation: NSUserInterfaceLayoutOrientation) {
        self.init()
        self.orientation = orientation
    }
}
