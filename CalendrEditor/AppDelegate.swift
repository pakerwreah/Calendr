//
//  AppDelegate.swift
//  CalendrEditor
//
//  Created by Paker on 21/08/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        let window = UIWindow()
        self.window = window

        let eventId = url.absoluteString.replacingOccurrences(of: "calendreditor://", with: "")
        let rootViewController = EventViewController(eventId: eventId)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        window.sizeToFit()

        return true
    }
}

