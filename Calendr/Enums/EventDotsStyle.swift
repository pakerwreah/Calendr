//
//  EventDotsStyle.swift
//  Calendr
//
//  Created by Paker on 07/10/2025.
//

import AppKit

enum EventDotsStyle: String, CaseIterable {
    case none
    case single_neutral
    case single_highlighted
    case multiple
}

extension EventDotsStyle {

    var title: String {
        switch self {
            case .none:
                return Strings.Settings.Calendar.EventDots.none
            case .single_neutral:
                return Strings.Settings.Calendar.EventDots.singleNeutral
            case .single_highlighted:
                return Strings.Settings.Calendar.EventDots.singleHighlighted
            case .multiple:
                return Strings.Settings.Calendar.EventDots.multiple
        }
    }

    static let netralColor: NSColor = .highlightColor
    static let highlightColor: NSColor = .controlAccentColor
}
