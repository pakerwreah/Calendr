//
//  NSView+Scroll.swift
//  Calendr
//
//  Created by Paker on 13/08/2026.
//

import AppKit

extension NSView {

    func scrollTop() {
        // NSTextView is flipped by default (which took me ages to figure out)
        scroll(.init(x: 0, y: isFlipped ? 0 : frame.height))
    }

    func hideVerticalScroller() {
        guard let enclosingScrollView else { return }
        enclosingScrollView.hasVerticalScroller = false
    }

    func showVerticalScroller() {
        guard let enclosingScrollView else { return }

        DispatchQueue.main.async {
            enclosingScrollView.hasVerticalScroller = true
            enclosingScrollView.reflectScrolledClipView(enclosingScrollView.contentView)
            enclosingScrollView.flashScrollers()
        }
    }
}
