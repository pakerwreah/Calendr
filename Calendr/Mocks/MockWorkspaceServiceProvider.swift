//
//  MockWorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 20/12/2024.
//

#if DEBUG

import AppKit.NSWorkspace
import UniformTypeIdentifiers

class MockWorkspaceServiceProvider: WorkspaceServiceProviding {

    let localStorage: LocalStorageProvider = .shared
    let dateProvider: DateProviding = MockDateProvider()
    let calendarAppProvider: CalendarAppProviding = MockCalendarAppProvider()
    let notificationCenter: NotificationCenter = .init()

    func urlForApplication(toOpen url: URL) -> URL? {
        return nil
    }
    
    func urlsForApplications(toOpen url: URL) -> [URL] {
        return []
    }
    
    func urlForApplication(toOpen contentType: UTType) -> URL? {
        return nil
    }
    
    func urlsForApplications(toOpen contentType: UTType) -> [URL] {
        return []
    }

    func open(_ url: URL) -> Bool {
        return true
    }

    func open(_ url: URL, withApplicationAt applicationURL: URL) { }

    func open(_ link: EventLink) { }

    func open(_ link: EventModel) { }
}

#endif
