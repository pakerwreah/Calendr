//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var viewController: NSViewController?
    private var appearanceObserver: Any!

    func applicationDidFinishLaunching(_ notification: Notification) {

        if NSClassFromString("XCTestCase") == nil {
            viewController = MainViewController()
        }

        // 🔨 Fix issue with NSColor.cgColor returning the wrong color when switching between dark & light themes
        appearanceObserver = NSApp.observe(\.effectiveAppearance, options: [.new]) { app, change in
            NSAppearance.current = change.newValue
        }
    }
}
