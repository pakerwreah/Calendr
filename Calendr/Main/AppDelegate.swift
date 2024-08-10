//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import Sentry

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
        if let dsn = Environment.SENTRY_DSN {
            SentrySDK.start { options in
                options.dsn = dsn
            }
        }
        #endif

        let userDefaults = UserDefaults.standard
        let notificationCenter = NotificationCenter.default
        let workspace = NSWorkspace.shared

        registerDefaultPrefs(in: userDefaults)

        let dateProvider = DateProvider(notificationCenter: notificationCenter, userDefaults: userDefaults)

        viewController = MainViewController(
            autoLauncher: .default,
            workspace: workspace,
            calendarService: CalendarServiceProvider(dateProvider: dateProvider, notificationCenter: notificationCenter),
            dateProvider: dateProvider,
            screenProvider: ScreenProvider(notificationCenter: notificationCenter),
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        setUpEditShortcuts()
        setUpResignFocus()
    }
}
