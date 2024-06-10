//
//  AppEditShortcuts.swift
//  Calendr
//
//  Created by Paker on 10/06/24.
//

import AppKit

extension AppDelegate {
    
    // 🔨 This will not be visible, but it allows us to use basic commands in text fields
    func setUpEditShortcuts() {

        let mainMenu = NSMenu(title: "MainMenu")
        let menuItem = mainMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")

        let submenu = NSMenu()
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
