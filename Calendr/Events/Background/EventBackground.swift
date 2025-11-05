//
//  EventBackground.swift
//  Calendr
//
//  Created by Paker on 06/01/2025.
//

import Cocoa

enum EventBackground: Equatable {
    case clear
    case pending
    case color(NSColor)
}

extension EventBackground {

    var cgColor: CGColor {
        switch self {
            case .clear: .clear
            case .pending: NSColor.gray.striped(alpha: 0.25).cgColor
            case .color(let color): color.cgColor
        }
    }
}
