//
//  PopoverMaterial.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

import AppKit

typealias PopoverMaterial = NSVisualEffectView.Material

extension PopoverMaterial {

    init(transparency: Int) {
        self = [
            .contentBackground,
            .sheet,
            .headerView,
            .menu,
            .popover,
            .hudWindow
        ][transparency]
    }
}
