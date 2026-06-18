//
//  Material.swift
//  Calendr
//
//  Created by Paker on 03/06/2026.
//

import SwiftUI

enum Material: Equatable {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var value: SwiftUI.Material {
        switch self {
            case .ultraThin: .ultraThin
            case .thin: .thin
            case .regular: .regular
            case .thick: .thick
            case .ultraThick: .ultraThick
        }
    }
}
