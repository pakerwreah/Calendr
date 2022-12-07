//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var viewController: NSViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {

        guard !BuildConfig.isTesting, !BuildConfig.isPreview else { return }

        #if DEBUG
        guard !BuildConfig.isUITesting else {
            viewController = MockMainViewController()
            return
        }
        #endif

        viewController = MainViewController(
            workspace: NSWorkspace.shared,
            calendarService: CalendarServiceProvider(notificationCenter: .default),
            dateProvider: DateProvider(calendar: .autoupdatingCurrent),
            screenProvider: ScreenProvider(notificationCenter: .default),
            userDefaults: .standard,
            notificationCenter: .default
        )

        setUpKeyboard()
    }

    // 🔨 This will not be visible, but it allows us to use basic commands in text fields
    private func setUpKeyboard() {

        let mainMenu = NSMenu(title: "MainMenu")
        let menuItem = mainMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")

        let submenu = NSMenu()
        submenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        submenu.addItem(withTitle: "Undo", action: #selector(EditMenuActions.undo(_:)), keyEquivalent: "z")
        submenu.addItem(withTitle: "Redo", action: #selector(EditMenuActions.redo(_:)), keyEquivalent: "Z")
        submenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        submenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        submenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        submenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.setSubmenu(submenu, for: menuItem)
        NSApp.mainMenu = mainMenu
    }
}

@objc private protocol EditMenuActions {
    func redo(_ sender: AnyObject)
    func undo(_ sender: AnyObject)
}
