//
//  WorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace
import UniformTypeIdentifiers

protocol WorkspaceServiceProviding {

    var localStorage: LocalStorageProvider { get }
    var dateProvider: DateProviding { get }
    var calendarAppProvider: CalendarAppProviding { get }
    var notificationCenter: NotificationCenter { get }

    func urlForApplication(toOpen url: URL) -> URL?

    func urlsForApplications(toOpen url: URL) -> [URL]

    func urlForApplication(toOpen contentType: UTType) -> URL?

    func urlsForApplications(toOpen contentType: UTType) -> [URL]

    @discardableResult func open(_ url: URL) -> Bool

    func open(_ url: URL, withApplicationAt applicationURL: URL)

    func open(_ link: EventLink)

    func open(_ event: EventModel)

    func open(_ date: Date, mode: CalendarViewMode)
}

private let httpsSchemeURL = URL(string: "https:")!
private let remindersSchemeURL = URL(string: "x-apple-reminderkit://")!

extension WorkspaceServiceProviding {

    private var calendarApp: CalendarApp {
        CalendarApp(rawValue: localStorage.defaultCalendarApp) ?? .calendar
    }

    private var calendarAppViewMode: CalendarViewMode {
        CalendarViewMode(rawValue: localStorage.calendarAppViewMode) ?? .month
    }

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
            let browserPath = localStorage.defaultBrowserPerCalendar[link.calendarId],
            let browserUrl = URL(string: browserPath)
        else {
            open(link.url)
            return
        }
        open(link.url, withApplicationAt: browserUrl)
    }

    func open(_ event: EventModel) {
        calendarAppProvider.open(event, preferring: calendarApp, using: self)
    }

    func open(_ date: Date) {
        open(date, mode: calendarAppViewMode)
    }

    func open(_ date: Date, mode: CalendarViewMode) {
        calendarAppProvider.open(calendarApp, at: date, mode: mode, using: self)
    }

    func open(_ attachment: Attachment) {

        guard let localURL = attachment.localURL else {
            if let url = attachment.url {
                _ = open(url)
            }
            return
        }

        var isStale = true
        var resolvedURL: URL?

        if let bookmarkData = localStorage.attachmentsBookmark {
            resolvedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        }

        if let resolvedURL, !isStale, resolvedURL.startAccessingSecurityScopedResource() {
            defer { resolvedURL.stopAccessingSecurityScopedResource() }
            if let relativePath = localURL.relativePath(from: resolvedURL) {
                let urlToOpen = resolvedURL.appendingPathComponent(relativePath)

                if !open(urlToOpen) {
                    localStorage.attachmentsBookmark = nil
                }
            }
            return
        }

        let directoryURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Group Containers/group.com.apple.calendar/Attachments")

        let panel = NSOpenPanel()
        panel.directoryURL = directoryURL
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = Strings.Attachments.Open.message
        panel.prompt = Strings.Attachments.Open.authorize

        panel.begin { [localStorage] (result) in
            guard
                result == .OK, let url = panel.url,
                url.startAccessingSecurityScopedResource()
            else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                localStorage.attachmentsBookmark = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            } catch {
                print("Failed to create bookmark: \(error)")
            }

            _ = self.open(localURL)
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openReminders() {
        if let appUrl = urlForApplication(toOpen: remindersSchemeURL) {
            open(appUrl)
        }
    }
}

class Workspace: WorkspaceServiceProviding {

    private let workspace: NSWorkspace = .shared

    let localStorage: LocalStorageProvider
    let dateProvider: DateProviding
    let calendarAppProvider: CalendarAppProviding
    let notificationCenter: NotificationCenter

    init(localStorage: LocalStorageProvider, dateProvider: DateProviding, calendarAppProvider: CalendarAppProviding) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.calendarAppProvider = calendarAppProvider
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
