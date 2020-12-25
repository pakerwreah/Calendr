//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    private let calendarView = CalendarView(viewModel: CalendarViewModel(yearObservable: .just(2020), monthObservable: .just(12)))

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        guard let view = window.contentView else { return }

        view.addSubview(calendarView)

        calendarView.edges(to: view)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.setIsVisible(true)
        return true
    }

}

