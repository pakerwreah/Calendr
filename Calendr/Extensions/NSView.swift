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
