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
        let calendarAppProvider = CalendarAppProvider(dateProvider: dateProvider, appleScriptRunner: AppleScriptRunner())
        let workspace = Workspace(userDefaults: userDefaults, dateProvider: dateProvider, calendarAppProvider: calendarAppProvider)
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

        #if DEBUG
        print(Bundle.main.bundlePath)
        #endif
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        deeplink.onNext(url)
    }

    private let signal: DispatchSourceSignal = {
        Darwin.signal(SIGTERM, SIG_IGN)

        let signal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signal.setEventHandler(handler: showQuitConfirmation)
        signal.activate()

        return signal
    }()
}

private func showQuitConfirmation() {
    let alert = NSAlert()
    alert.messageText = "Are you sure you want to quit?"
    alert.informativeText = "This can happen due to low disk space, memory pressure, or \"cleaning\" apps."
    alert.alertStyle = .warning

    alert.addButton(withTitle: "Quit").hasDestructiveAction = true
    alert.addButton(withTitle: "Keep Running")

    if alert.runModal() == .alertFirstButtonReturn {
        NSApp.terminate(nil)
    }
}
