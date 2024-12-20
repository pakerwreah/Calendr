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
    let userDefaults: UserDefaults
    let dateProvider: DateProviding
    let notificationCenter: NotificationCenter

    init() {
        userDefaults = .init(suiteName: String(describing: Self.self))!
        dateProvider = MockDateProvider()
        notificationCenter = .init()
    }

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
