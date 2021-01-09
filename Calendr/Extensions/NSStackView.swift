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

    func addArrangedSubviews(_ views: NSView...) {
        addArrangedSubviews(views)
    }

    func addArrangedSubviews(_ views: [NSView]) {
        views.forEach(addArrangedSubview)
    }
}

extension NSView {
    static var spacer: NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return spacer
    }
}
