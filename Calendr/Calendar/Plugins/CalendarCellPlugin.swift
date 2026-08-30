//
//  CalendarCellPlugin.swift
//  Calendr
//
//  Created by Paker on 29/08/2026.
//

import AppKit

protocol CalendarCellPlugin: Equatable {
    var text: String? { get }
    var textColor: NSColor? { get }
    var font: NSFont? { get }
    var spacing: CGFloat? { get }
}

extension CalendarCellPlugin {
    var text: String? { nil }
    var textColor: NSColor? { nil }
    var font: NSFont? { nil }
    var spacing: CGFloat? { nil }
}

struct AnyCalendarCellPlugin: CalendarCellPlugin {
    let text: String?
    let textColor: NSColor?
    let font: NSFont?
    let spacing: CGFloat?
}

extension CalendarCellPlugin {

    func eraseToAnyPlugin() -> AnyCalendarCellPlugin {
        .init(
            text: text,
            textColor: textColor,
            font: font,
            spacing: spacing
        )
    }
}
