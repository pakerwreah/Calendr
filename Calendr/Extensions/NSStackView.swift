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
        spacer.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        spacer.setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
        spacer.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeCompression, for: .vertical)
        return spacer
    }

    static func spacer(width: CGFloat) -> NSView {
        NSView.spacer.width(equalTo: width)
    }

    static func spacer(height: CGFloat) -> NSView {
        NSView.spacer.height(equalTo: height)
    }
}
