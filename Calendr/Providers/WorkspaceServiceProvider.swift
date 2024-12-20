//
//  WorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace
import UniformTypeIdentifiers

protocol WorkspaceServiceProviding {

    var userDefaults: UserDefaults { get }
    var dateProvider: DateProviding { get }
    var notificationCenter: NotificationCenter { get }

    func urlForApplication(toOpen url: URL) -> URL?

    func urlsForApplications(toOpen url: URL) -> [URL]

    func urlForApplication(toOpen contentType: UTType) -> URL?

    func urlsForApplications(toOpen contentType: UTType) -> [URL]

    @discardableResult func open(_ url: URL) -> Bool

    func open(_ url: URL, withApplicationAt applicationURL: URL)

    func open(_ link: EventLink)

    func open(_ event: EventModel)
}

private let httpsSchemeURL = URL(string: "https:")!

extension WorkspaceServiceProviding {

    func supports(scheme: String) -> Bool {
        URL(string: scheme).flatMap(urlForApplication(toOpen:)) != nil
    }

    func urlForDefaultBrowserApplication() -> URL? {
        urlForApplication(toOpen: .html)
    }

    func urlsForBrowsersApplications() -> [URL] {
        let htmlHandlerAppsURLs = urlsForApplications(toOpen: .html)
        let httpsHandlerAppsURLs = urlsForApplications(toOpen: httpsSchemeURL)

        return Array(Set(htmlHandlerAppsURLs).intersection(httpsHandlerAppsURLs))
    }

    func open(_ link: EventLink) {
        guard
            !link.isNative,
            let browserPath = userDefaults.defaultBrowserPerCalendar[link.calendarId],
            let browserUrl = URL(string: browserPath)
        else {
            open(link.url)
            return
        }
        open(link.url, withApplicationAt: browserUrl)
    }

    func open(_ event: EventModel) {
        open(event.calendarAppURL(using: dateProvider))
    }
}

class Workspace: WorkspaceServiceProviding {

    private let workspace: NSWorkspace = .shared

    let userDefaults: UserDefaults
    let dateProvider: DateProviding
    let notificationCenter: NotificationCenter

    init(userDefaults: UserDefaults, dateProvider: DateProviding) {
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
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
        Popover.closeAll()
        return workspace.open(url)
    }

    func open(_ url: URL, withApplicationAt applicationURL: URL) {
        Popover.closeAll()
        workspace.open([url], withApplicationAt: applicationURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
