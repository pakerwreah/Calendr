//
//  AppearanceMode.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

import AppKit

enum AppearanceMode: Int, CaseIterable {
    case automatic, light, dark
}

extension AppearanceMode {

    var appearance: NSAppearance? {
        switch self {
        case .automatic:
            return nil
        case .light:
            return .init(named: .aqua)
        case .dark:
            return .init(named: .darkAqua)
        }
    }
}
