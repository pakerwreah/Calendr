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
        #else
        let appLaunch = startSentry()
        defer { appLaunch?.finish() }
        #endif

        let userDefaults = UserDefaults.standard
        let notificationCenter = NotificationCenter.default
        let workspace = NSWorkspace.shared
        let fileManager = FileManager.default

        registerDefaultPrefs(in: userDefaults)

        let dateProvider = DateProvider(notificationCenter: notificationCenter, userDefaults: userDefaults)
        let notificationProvider = LocalNotificationProvider()

        viewController = MainViewController(
            autoLauncher: .default,
            workspace: workspace,
            calendarService: CalendarServiceProvider(
                dateProvider: dateProvider,
                workspace: workspace,
                userDefaults: userDefaults,
                notificationCenter: notificationCenter
            ),
            geocoder: GeocodeServiceProvider(),
            dateProvider: dateProvider,
            screenProvider: ScreenProvider(notificationCenter: notificationCenter), 
            notificationProvider: notificationProvider,
            networkProvider: NetworkServiceProvider(),
            userDefaults: userDefaults,
            notificationCenter: notificationCenter,
            fileManager: fileManager
        )

        setUpEditShortcuts()
        setUpResignFocus()
    }
}
