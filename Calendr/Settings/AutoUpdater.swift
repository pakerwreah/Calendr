//
//  AutoUpdater.swift
//  Calendr
//
//  Created by Paker on 17/08/2024.
//

import AppKit
import UserNotifications
import RxSwift
import ZIPFoundation
import Sentry

enum UpdateStatus {
    case initial
    case fetching
    case newVersion(String)
    case downloading(String)
}

enum UpdateError {
    case check(Error)
    case download(Error)
    case install(Error)

    var title: String {
        switch self {
            case .check: Strings.AutoUpdate.Failed.check
            case .download: Strings.AutoUpdate.Failed.download
            case .install: Strings.AutoUpdate.Failed.install
        }
    }

    var message: String {
        switch self {
            case .check(let error), .download(let error), .install(let error):
                error.localizedDescription
        }
    }
}

protocol AutoUpdating {
    var status: Observable<UpdateStatus> { get }
    var error: Observable<UpdateError> { get }

    @MainActor func start()
    func checkRelease()
    func downloadAndInstall()
}

class AutoUpdater: AutoUpdating {

    enum NotificationAction {

        enum NewVersion: String {
            case `default`
            case install
        }

        enum Updated: String {
            case `default`
        }

        case newVersion(NewVersion)
        case updated(Updated)

        fileprivate static func from(_ response: NotificationResponse) -> NotificationAction {

            switch response.category {
            case .newVersion:
                return NotificationAction.newVersion(
                    response.actionId.flatMap(NotificationAction.NewVersion.init(rawValue:)) ?? .default
                )

            case .updated:
                return NotificationAction.updated(
                    response.actionId.flatMap(NotificationAction.Updated.init(rawValue:)) ?? .default
                )
            }
        }
    }

    private let newVersionCategory = UNNotificationCategory(
        categoryId: NotificationCategory.newVersion.rawValue,
        actionId: NotificationAction.NewVersion.install.rawValue,
        title: Strings.AutoUpdate.install
    )

    private let updatedCategory = UNNotificationCategory(
        categoryId: NotificationCategory.updated.rawValue
    )

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
        }
        let name: String
        let assets: [Asset]
    }

    let notificationTap: Observable<NotificationAction>

    private let statusObserver: AnyObserver<UpdateStatus>
    let status: Observable<UpdateStatus>

    private let errorObserver: AnyObserver<UpdateError>
    let error: Observable<UpdateError>

    private var newRelease: Release?

    private let localStorage: LocalStorageProvider
    private(set) var notificationProvider: LocalNotificationProviding
    private let networkProvider: NetworkServiceProviding
    private let fileManager: FileManager

    init(
        localStorage: LocalStorageProvider,
        notificationProvider: LocalNotificationProviding,
        networkProvider: NetworkServiceProviding,
        fileManager: FileManager
    ) {
        self.localStorage = localStorage
        self.notificationProvider = notificationProvider
        self.networkProvider = networkProvider
        self.fileManager = fileManager

        (status, statusObserver) = BehaviorSubject.pipe(value: .initial)
        (error, errorObserver) = PublishSubject.pipe()

        notificationTap = notificationProvider.notificationTap.map(NotificationAction.from)

        setUpNotifications()

        cleanUpDownloads()
    }

    func start() {

        guard !BuildConfig.isUITesting, !BuildConfig.isDebug else { return }

        Task {
            guard await notificationProvider.requestAuthorization() else { return }

            self.checkRelease(notify: true)

            DispatchQueue.main.async {
                Timer.scheduledTimer(
                    withTimeInterval: 3 * 60 * 60,
                    repeats: true
                ) { [weak self] _ in
                    self?.checkRelease(notify: true)
                }
            }
        }
    }

    func checkRelease() {
        checkRelease(notify: false)
    }

    private func checkRelease(notify: Bool) {
        Task {
            do {
                try await checkReleaseAsync(notify: notify)
            } catch {
                print(error)
                errorObserver.onNext(.check(error))
                statusObserver.onNext(.initial)
            }
        }
    }

    func downloadAndInstall() {
        Task {
            do {
                try await downloadAndInstallAsync()
            } catch {
                SentrySDK.capture(error: error)
                statusObserver.onNext(.initial)
            }
        }
    }

    private func downloadAndInstallAsync() async throws {
        guard
            let release = newRelease,
            let url = release.assets.first(where: { $0.name == "Calendr.zip" })?.browser_download_url
        else {
            throw .unexpected("Missing release asset")
        }

        statusObserver.onNext(.downloading(release.name))

        let archiveURL: URL
        do {
            archiveURL = try await networkProvider.download(from: url)
        } catch {
            errorObserver.onNext(.download(error))
            throw error
        }

        do {
            try await install(version: release.name, archiveUrl: archiveURL)
        } catch {
            errorObserver.onNext(.install(error))
            throw error
        }

        // if there's no error, the user just cancelled
        statusObserver.onNext(.newVersion(release.name))
    }

    private func setUpNotifications() {
        
        notificationProvider.register(newVersionCategory, updatedCategory)
        
        sendUpdatedNotification()
    }

    private func sendUpdatedNotification()  {

        guard let updated = localStorage.updatedVersion else { return }

        localStorage.updatedVersion = nil

        guard updated == BuildConfig.appVersion else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.AutoUpdate.updatedTo("\(BuildConfig.appVersion) 🎉")
        content.sound = .default
        content.categoryIdentifier = updatedCategory.identifier

        notificationProvider.send(id: .uuid, content)
    }

    private func checkReleaseAsync(notify: Bool) async throws {

        guard !BuildConfig.isUITesting else { return }

        statusObserver.onNext(.fetching)

        let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
        let data = try await networkProvider.data(from: URL(string: url)!)
        let release = try JSONDecoder().decode(Release.self, from: data)

        guard release.name != BuildConfig.appVersion else {
            statusObserver.onNext(.initial)
            localStorage.lastCheckedVersion = release.name
            return
        }

        newRelease = release
        statusObserver.onNext(.newVersion(release.name))

        guard notify else {
            localStorage.lastCheckedVersion = release.name
            return
        }

        guard release.name != localStorage.lastCheckedVersion else {
            return // only notify each version once
        }

        await sendNotification(version: release.name)
    }

    private func sendNotification(version: String) async {

        let content = UNMutableNotificationContent()
        content.title = Strings.AutoUpdate.newVersion(version)
        content.sound = .default
        content.categoryIdentifier = newVersionCategory.identifier

        if await notificationProvider.send(id: .uuid, content) {
            localStorage.lastCheckedVersion = version
        }
    }

    private func getApplicationsUrl() -> URL? {
        try? fileManager.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: false)
    }

    private func getAppContainerUrl() -> URL {
        let appUrl = Bundle.main.bundleURL
        /// gatekeeper might go nuts if you restore the app from the trash 🔮
        if appUrl.pathComponents.contains("AppTranslocation"), let applications = getApplicationsUrl() {
            return applications
        }
        return appUrl.deletingLastPathComponent()
    }

    private func install(version: String, archiveUrl: URL) async throws {

        let containerUrl = getAppContainerUrl()

        defer { try? fileManager.removeItem(at: archiveUrl) }

        try await withSecurityScope(for: containerUrl) { secureUrl in
            let appUrl = secureUrl.withAppComponent()
            try replaceApp(url: appUrl, archive: archiveUrl)
        }

        localStorage.updatedVersion = version

        let appUrl = containerUrl.withAppComponent()
        try await relaunchApp(url: appUrl)
    }

    private func withSecurityScope(for appContainerUrl: URL, _ task: (URL) async throws -> Void) async throws {

        var isStale = true
        var resolvedURL: URL?

        if let bookmarkData = localStorage.installationBookmark {
            resolvedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        }

        if let resolvedURL, !isStale, resolvedURL == appContainerUrl, resolvedURL.startAccessingSecurityScopedResource() {
            defer { resolvedURL.stopAccessingSecurityScopedResource() }
            return try await task(resolvedURL)
        }

        // if we can't access the secure bookmark, ask the user for permission
        guard try await savePanel(for: appContainerUrl) else {
            return // user cancelled
        }

        do {
            localStorage.installationBookmark = try appContainerUrl.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            SentrySDK.capture(error: error)
            print("Failed to create bookmark: \(error)")
        }

        try await task(appContainerUrl)
    }

    @MainActor
    private func savePanel(for appContainerUrl: URL) async throws -> Bool {
        NSApp.modalWindow?.close()

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = appContainerUrl
        panel.prompt = Strings.AutoUpdate.install
        panel.message = Strings.AutoUpdate.Replace.message

        guard await panel.begin() == .OK, let url = panel.url else {
            return false
        }

        guard url == appContainerUrl else {
            errorObserver.onNext(.install(.unexpected(Strings.AutoUpdate.Replace.error)))
            return false
        }

        return true
    }

    private func replaceApp(url appUrl: URL, archive archiveURL: URL) throws {

        guard appUrl.lastPathComponent == "Calendr.app" else {
            throw .unexpected("This is not the app we want to replace: \(appUrl)")
        }

        try fileManager.trashItem(at: appUrl, resultingItemURL: nil)

        let archive: Archive
        do {
            archive = try Archive(url: archiveURL, accessMode: .read)
        } catch {
            throw .unexpected("[Archive] \(error)")
        }

        do {
            for entry in archive where entry.path.starts(with: "Calendr.app/") {
                let entryURL = appUrl.deletingLastPathComponent().appendingPathComponent(entry.path)
                _ = try archive.extract(entry, to: entryURL)
            }
        } catch {
            throw .unexpected("[Extract] \(error)")
        }
    }

    private func cleanUpDownloads() {
        let tmp = fileManager.temporaryDirectory
        guard
            let bundleID = Bundle.main.bundleIdentifier,
            // make sure we are sandboxed
            tmp.absoluteString.contains(bundleID)
        else {
            return
        }
        try? fileManager.removeItem(at: tmp)
    }

    @MainActor
    private func relaunchApp(url: URL) throws {

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", url.path]
        try task.run()

        task.waitUntilExit()

        NSApp.terminate(nil)
    }
}

private extension URL {

    func withAppComponent() -> URL {
        appending(component: "Calendr.app", directoryHint: .isDirectory)
    }
}
