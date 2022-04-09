//
//  ScreenProvider.swift
//  Calendr
//
//  Created by Paker on 09/04/22.
//

import AppKit.NSScreen

protocol ScreenProviding {
    var hasNotch: Bool { get }
}

class ScreenProvider: ScreenProviding {
    var hasNotch: Bool {
        guard #available(macOS 12, *) else { return false }
        return NSScreen.main?.auxiliaryTopRightArea != nil
    }
}
