//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class AppDelegate: NSObject, NSApplicationDelegate {

    private var viewController: MainViewController?

    private let deeplink = BehaviorSubject<URL?>(value: nil)

    private let disposeBag = DisposeBag()

    private let skipReopen = BehaviorSubject(value: false)

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

        let localStorage = LocalStorageProvider.shared
        let notificationCenter = NotificationCenter.default
        let fileManager = FileManager.default

        registerDefaultPrefs(in: localStorage)

        let dateProvider = DateProvider(notificationCenter: notificationCenter, localStorage: localStorage)
        let calendarAppProvider = CalendarAppProvider(dateProvider: dateProvider, appleScriptRunner: AppleScriptRunner(), clock: .continuous)
        let workspace = Workspace(localStorage: localStorage, dateProvider: dateProvider, calendarAppProvider: calendarAppProvider)
        let notificationProvider = LocalNotificationProvider()

        viewController = MainViewController(
            deeplink: deeplink.skipNil(),
            autoLauncher: AutoLauncher(),
            workspace: workspace,
            calendarService: CalendarServiceProvider(
                dateProvider: dateProvider,
                workspace: workspace,
                localStorage: localStorage,
                notificationCenter: notificationCenter
            ),
            geocoder: GeocodeServiceProvider(),
            weatherService: WeatherServiceProvider(dateProvider: dateProvider),
            dateProvider: dateProvider,
            screenProvider: ScreenProvider(notificationCenter: notificationCenter),
            notificationProvider: notificationProvider,
            networkProvider: NetworkServiceProvider(),
            localStorage: localStorage,
            notificationCenter: notificationCenter,
            fileManager: fileManager
        )

        setUpEditShortcuts()
        setUpResignFocus()

        notificationProvider.notificationTap
            .map(true)
            .bind(to: skipReopen)
            .disposed(by: disposeBag)

        #if DEBUG
        print(Bundle.main.bundlePath)
        #endif
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        deeplink.onNext(url)
    }


    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if let viewController, !hasVisibleWindows, !skipReopen.current {
            viewController.openSettings()
        }
        skipReopen.onNext(false)
        return false
    }

    private let activity = {
        ProcessInfo.processInfo.beginActivity(
            options: [
                .userInitiatedAllowingIdleSystemSleep,
                .automaticTerminationDisabled,
                .suddenTerminationDisabled
            ],
            reason: "Stop killing my app!"
        )
    }()
}
