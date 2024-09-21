//
//  NSView.swift
//  Calendr
//
//  Created by Paker on 07/02/21.
//

import Cocoa

extension NSView {

    func scrollTop() { scroll(.init(x: 0, y: frame.height)) }
}

// MARK: - Factory

extension NSView {

    static var dummy: NSView {
        let spacer = NSView.spacer
        spacer.width(equalTo: 0, priority: .defaultHigh)
        spacer.height(equalTo: 0, priority: .defaultHigh)
        return spacer
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
