//
//  StatusItemBackgroundStyle.swift
//  Calendr
//
//  Created by Paker on 11/07/2026.
//

enum StatusItemBackgroundStyle: String, CaseIterable {
    case transparent, outline, opaque
}

extension StatusItemBackgroundStyle {

    var title: String {
        switch self {
            case .transparent:
                return Strings.Settings.MenuBar.Background.transparent
            case .outline:
                return Strings.Settings.MenuBar.Background.outline
            case .opaque:
                return Strings.Settings.MenuBar.Background.opaque
        }
    }
}
