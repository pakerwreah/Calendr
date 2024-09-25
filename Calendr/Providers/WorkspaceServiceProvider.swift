//
//  WorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace
import UniformTypeIdentifiers

protocol WorkspaceServiceProviding {

    var notificationCenter: NotificationCenter { get }

    func urlForApplication(toOpen url: URL) -> URL?

    func urlsForApplications(toOpen url: URL) -> [URL]

    func urlForApplication(toOpen contentType: UTType) -> URL?

    func urlsForApplications(toOpen contentType: UTType) -> [URL]

    @discardableResult func open(_ url: URL) -> Bool

    @discardableResult func open(_ link: EventLink) -> Bool
}

private let httpsSchemeURL = URL(string: "https:")!

extension WorkspaceServiceProviding {

    func supports(scheme: String) -> Bool {
        URL(string: scheme).flatMap(urlForApplication(toOpen:)) != nil
    }

    func urlForDefaultBrowserApplication() -> URL {
        urlForApplication(toOpen: .html)!
    }

    func urlsForBrowsersApplications() -> [URL] {
        let htmlHandlerAppsURLs = urlsForApplications(toOpen: .html)
        let httpsHandlerAppsURLs = urlsForApplications(toOpen: httpsSchemeURL)

        return Array(Set(htmlHandlerAppsURLs).intersection(httpsHandlerAppsURLs))
    }

    func open(_ link: EventLink) -> Bool {
        return false
    }
}

extension NSWorkspace: WorkspaceServiceProviding { }

class Workspace: WorkspaceServiceProviding {

    private let userDefaults: UserDefaults
    private let workspace: NSWorkspace
    let notificationCenter: NotificationCenter

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.workspace = .shared
        self.notificationCenter = workspace.notificationCenter
    }

    func urlForApplication(toOpen url: URL) -> URL? {
        workspace.urlForApplication(toOpen: url)
    }

    func urlsForApplications(toOpen url: URL) -> [URL] {
        workspace.urlsForApplications(toOpen: url)
    }

    func urlForApplication(toOpen contentType: UTType) -> URL? {
        workspace.urlForApplication(toOpen: contentType)
    }

    func urlsForApplications(toOpen contentType: UTType) -> [URL] {
        workspace.urlsForApplications(toOpen: contentType)
    }

    func open(_ url: URL) -> Bool {
        workspace.open(url)
    }

    func open(_ link: EventLink) -> Bool {
        guard
            !link.isMeeting,
            let browserPath = userDefaults.defaultBrowserPerCalendar[link.calendarId],
            let browserUrl = URL(string: browserPath)
        else {
            return open(link.url)
        }
        return open(browserUrl)
    }
}
