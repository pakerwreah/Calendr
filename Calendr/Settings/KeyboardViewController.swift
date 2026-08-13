//
//  KeyboardViewController.swift
//  Calendr
//
//  Created by Paker on 13/08/2026.
//

import AppKit

class KeyboardViewController: NSTabViewController, SettingsUI {

    override func viewDidLoad() {

        super.viewDidLoad()

        let localShortcuts = NSTabViewItem(viewController: LocalShortcutsViewController())
        let globalShortcuts = NSTabViewItem(viewController: GlobalShortcutsViewController())

        tabViewItems = [localShortcuts, globalShortcuts]

        for item in tabViewItems {
            item.label = item.viewController?.title ?? ""
        }
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {

        super.tabView(tabView, didSelect: tabViewItem)

        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
    }
}
