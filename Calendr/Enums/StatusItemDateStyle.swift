//
//  StatusItemDateStyle.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

import AppKit

typealias StatusItemDateStyle = DateFormatter.Style

extension StatusItemDateStyle {
    static let allCases: [Self] = [.short, .medium, .long, .full]
    var isCustom: Bool { !Self.allCases.contains(self) }
}
