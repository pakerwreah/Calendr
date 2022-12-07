//
//  NSColor.swift
//  Calendr
//
//  Created by Paker on 07/12/2022.
//

import AppKit

extension NSColor {

    // 🔨 Fix issue with cgColor returning the wrong color after switching between dark & light themes
    var effectiveCGColor: CGColor {
        var color: CGColor!
        NSApp.effectiveAppearance.performAsCurrentDrawingAppearance {
            color = cgColor
        }
        return color
    }
}
