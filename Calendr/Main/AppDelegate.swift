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

func registerDefaultPrefs(in userDefaults: UserDefaults, calendar: Calendar = .current) {

    userDefaults.register(defaults: [
        Prefs.statusItemIconEnabled: true,
        Prefs.statusItemDateEnabled: true,
        Prefs.statusItemBackgroundEnabled: false,
        Prefs.statusItemIconStyle: StatusItemIconStyle.calendar.rawValue,
        Prefs.statusItemDateStyle: StatusItemDateStyle.short.rawValue,
        Prefs.statusItemDateFormat: "E d MMM yyyy",
        Prefs.showEventStatusItem: false,
        Prefs.eventStatusItemFontSize: 12,
        Prefs.eventStatusItemCheckRange: 6,
        Prefs.eventStatusItemLength: 18,
        Prefs.eventStatusItemDetectNotch: false,
        Prefs.calendarScaling: 1,
        Prefs.firstWeekday: calendar.firstWeekday,
        Prefs.highlightedWeekdays: [0, 6],
        Prefs.showWeekNumbers: false,
        Prefs.showDeclinedEvents: false,
        Prefs.preserveSelectedDate: false,
        Prefs.showPastEvents: true,
        Prefs.transparencyLevel: 2
    ])
}
