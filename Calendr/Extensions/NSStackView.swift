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

    func with(orientation: NSUserInterfaceLayoutOrientation) -> Self {
        self.orientation = orientation
        return self
    }

    func with(alignment: NSLayoutConstraint.Attribute) -> Self {
        self.alignment = alignment
        return self
    }

    func with(spacing: CGFloat) -> Self {
        self.spacing = spacing
        return self
    }

    func with(insets: NSEdgeInsets) -> Self {
        self.edgeInsets = insets
        return self
    }
}
