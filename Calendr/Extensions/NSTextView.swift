//
//  NSTextView.swift
//  Calendr
//
//  Created by Paker on 24/11/2022.
//

import Cocoa

extension NSTextView {

    var contentSize: CGSize {
        get {
            guard let layoutManager = layoutManager, let textContainer = textContainer else {
                print("textView no layoutManager or textContainer")
                return .zero
            }
            layoutManager.ensureLayout(for: textContainer)
            return layoutManager.usedRect(for: textContainer).size
        }
    }
}
