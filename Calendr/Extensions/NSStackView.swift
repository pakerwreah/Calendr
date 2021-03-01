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
}

extension NSView {

    static var dummy: NSView {
        NSView.spacer.with(width: 0).with(height: 0)
    }

    static var spacer: NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        spacer.setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
        spacer.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeCompression, for: .vertical)
        return spacer
    }

    static func spacer(width: CGFloat) -> NSView {
        NSView.spacer.with(width: width)
    }

    static func spacer(height: CGFloat) -> NSView {
        NSView.spacer.with(height: height)
    }
}
