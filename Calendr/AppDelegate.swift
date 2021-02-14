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

        if #available(OSX 11.0, *), NSClassFromString("XCTestCase") == nil {
            viewController = MainViewController()
        }
    }
}
