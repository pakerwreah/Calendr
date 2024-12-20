//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class AppDelegate: NSObject, NSApplicationDelegate {

    private var viewController: NSViewController?

    private let deeplink = BehaviorSubject<URL?>(value: nil)

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
        let fileManager = FileManager.default

        registerDefaultPrefs(in: userDefaults)

        let dateProvider = DateProvider(notificationCenter: notificationCenter, userDefaults: userDefaults)
        let workspace = Workspace(userDefaults: userDefaults, dateProvider: dateProvider)
        let notificationProvider = LocalNotificationProvider()

        viewController = MainViewController(
            deeplink: deeplink.skipNil(),
            autoLauncher: .default,
            workspace: workspace,
            calendarService: CalendarServiceProvider(
                dateProvider: dateProvider,
                workspace: workspace,
                userDefaults: userDefaults,
                notificationCenter: notificationCenter
            ),
            geocoder: GeocodeServiceProvider(),
            weatherService: .make(dateProvider: dateProvider),
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

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        deeplink.onNext(url)
    }
}
