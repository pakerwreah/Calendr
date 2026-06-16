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
    typealias NotificationAction = AutoUpdater.NotificationAction

    var status: Observable<UpdateStatus> { get }
    var error: Observable<UpdateError> { get }
    var notificationTap: Observable<NotificationAction> { get }

    @MainActor func start()
    @MainActor func stop()
    @MainActor func checkRelease()
    @MainActor func downloadAndInstall()
}

private class AutoUpdaterSaveModalFactory: SaveModalFactory {

    func make(for url: URL) -> SaveModal {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = url
        panel.prompt = Strings.AutoUpdate.install
        panel.message = Strings.AutoUpdate.Replace.message
        return panel
    }
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

    enum NotificationCategory {

        static let newVersion = UNNotificationCategory(
            categoryId: LocalNotification.Category.newVersion.rawValue,
            actionId: NotificationAction.NewVersion.install.rawValue,
            title: Strings.AutoUpdate.install
        )

        static let updated = UNNotificationCategory(
            categoryId: LocalNotification.Category.updated.rawValue
        )
    }

    private struct Release {
        let name: String
        let downloadURL: URL
    }

    let notificationTap: Observable<NotificationAction>

    private let statusObserver: AnyObserver<UpdateStatus>
    let status: Observable<UpdateStatus>

    private let errorObserver: AnyObserver<UpdateError>
    let error: Observable<UpdateError>

    private var newRelease: Release?

    private let launchServices: LaunchServiceProviding
    private let localStorage: LocalStorageProvider
    private(set) var notificationProvider: LocalNotificationProviding
    private let networkProvider: NetworkServiceProviding
    private let fileProvider: FileProviding
    private let saveModalFactory: SaveModalFactory
    private let bundleInfo: BundleInfo

    init(
        launchServices: LaunchServiceProviding,
        localStorage: LocalStorageProvider,
        notificationProvider: LocalNotificationProviding,
        networkProvider: NetworkServiceProviding,
        fileProvider: FileProviding,
        bundleInfo: BundleInfo,
        saveModalFactory: SaveModalFactory = AutoUpdaterSaveModalFactory()
    ) {
        self.launchServices = launchServices
        self.localStorage = localStorage
        self.notificationProvider = notificationProvider
        self.networkProvider = networkProvider
        self.fileProvider = fileProvider
        self.saveModalFactory = saveModalFactory
        self.bundleInfo = bundleInfo

        (status, statusObserver) = BehaviorSubject.pipe(value: .initial)
        (error, errorObserver) = PublishSubject.pipe()

        notificationTap = notificationProvider.notificationTap.map(NotificationAction.from)

        setUpNotifications()

        cleanUpDownloads()
    }

    private var autoCheck: Task<Void, Error>?

    func start() {
        autoCheck?.cancel()

        autoCheck = Task {
            while !Task.isCancelled {
                await self.checkRelease(notify: true)
                try await Task.sleep(for: .seconds(3 * 60 * 60))
            }
        }
    }

    func stop() {
        autoCheck?.cancel()
        autoCheck = nil
    }

    func checkRelease() {
        Task {
            await checkRelease(notify: false)
        }
    }

    private func checkRelease(notify: Bool) async {
        guard await notificationProvider.requestAuthorization() else { return }
        do {
            try await checkReleaseAsync(notify: notify)
        } catch {
            errorObserver.onNext(.check(error))
            statusObserver.onNext(.initial)
        }
    }

    func downloadAndInstall() {
        Task {
            do {
                try await downloadAndInstallAsync()
            } catch {
                statusObserver.onNext(.initial)
            }
        }
    }

    private func downloadAndInstallAsync() async throws {
        guard let release = newRelease else {
            throw .unexpected("Missing release")
        }

        statusObserver.onNext(.downloading(release.name))

        let archiveURL: URL
        do {
            archiveURL = try await networkProvider.download(from: release.downloadURL)
        } catch {
            errorObserver.onNext(.download(error))
            throw error
        }

        do {
            try await install(version: release.name, archiveUrl: archiveURL)
        } catch {
            SentrySDK.capture(error: error)
            errorObserver.onNext(.install(error))
            throw error
        }
    }

    private func setUpNotifications() {
        
        notificationProvider.register(
            NotificationCategory.newVersion,
            NotificationCategory.updated
        )

        sendUpdatedNotification()
    }

    private func sendUpdatedNotification()  {

        guard let updated = localStorage.updatedVersion else { return }

        localStorage.updatedVersion = nil

        guard updated == BuildConfig.appVersion else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.AutoUpdate.updatedTo("\(BuildConfig.appVersion) 🎉")
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.updated.identifier

        notificationProvider.send(id: .uuid, content)
    }

    private func checkReleaseAsync(notify: Bool) async throws {

        guard !BuildConfig.isUITesting else { return }

        statusObserver.onNext(.fetching)

        let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
        let data = try await networkProvider.data(from: URL(string: url)!)

        struct Response: Decodable {
            struct Asset: Decodable {
                let name: String
                let browser_download_url: URL
            }
            let name: String
            let assets: [Asset]
        }

        let release = try JSONDecoder().decode(Response.self, from: data)

        guard release.name != BuildConfig.appVersion else {
            statusObserver.onNext(.initial)
            localStorage.lastCheckedVersion = release.name
            return
        }

        guard let asset = release.assets.first(where: { $0.name == "Calendr.zip" }) else {
            throw .unexpected("Missing release asset")
        }

        newRelease = Release(name: release.name, downloadURL: asset.browser_download_url)
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
        content.categoryIdentifier = NotificationCategory.newVersion.identifier

        if await notificationProvider.send(id: .uuid, content) {
            localStorage.lastCheckedVersion = version
        }
    }

    private func getApplicationsFolderUrl() -> URL? {
        fileProvider.url(for: .applicationDirectory)
    }

    private func getAppContainingFolderUrl() -> URL {
        let appUrl = bundleInfo.bundleURL
        /// gatekeeper might go nuts if you restore the app from the trash 🔮
        if appUrl.pathComponents.contains("AppTranslocation"), let applications = getApplicationsFolderUrl() {
            return applications
        }
        return appUrl.deletingLastPathComponent()
    }

    private func install(version: String, archiveUrl: URL) async throws {

        let containerUrl = getAppContainingFolderUrl()

        defer { try? fileProvider.removeItem(at: archiveUrl) }

        let installed = try await withSecurityScope(for: containerUrl) { secureUrl in
            let appUrl = secureUrl.withAppComponent()
            try replaceApp(url: appUrl, archive: archiveUrl)
        }

        // if there's no error, the user just cancelled
        guard installed else {
            statusObserver.onNext(.newVersion(version))
            return
        }

        localStorage.updatedVersion = version
        localStorage.synchronize()

        try await launchServices.relaunch(at: containerUrl.withAppComponent())
    }

    private func withSecurityScope(for appContainerUrl: URL, _ task: (URL) async throws -> Void) async throws -> Bool {

        var isStale = true
        var resolvedURL: URL?

        if let bookmarkData = localStorage.installationBookmark {
            resolvedURL = fileProvider.resolveSecurityScopedURL(from: bookmarkData, isStale: &isStale)
        }

        if let resolvedURL, !isStale, resolvedURL == appContainerUrl, fileProvider.startAccessingSecurityScopedResource(resolvedURL) {
            defer { fileProvider.stopAccessingSecurityScopedResource(resolvedURL) }
            try await task(resolvedURL)
            return true
        }

        // if we can't access the secure bookmark, ask the user for permission
        guard await requestPermission(for: appContainerUrl) else {
            return false
        }

        do {
            localStorage.installationBookmark = try fileProvider.bookmarkData(for: appContainerUrl)
        } catch {
            SentrySDK.capture(error: error)
            print("Failed to create bookmark: \(error)")
        }

        try await task(appContainerUrl)
        return true
    }

    @MainActor
    private func requestPermission(for appContainerUrl: URL) async -> Bool {
        NSApp?.modalWindow?.close()

        let panel = saveModalFactory.make(for: appContainerUrl)

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

        try fileProvider.trashItem(at: appUrl)

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
        let tmp = fileProvider.temporaryDirectory
        guard
            let bundleID = bundleInfo.bundleIdentifier,
            // make sure we are sandboxed
            tmp.absoluteString.contains(bundleID)
        else {
            return
        }
        try? fileProvider.removeItem(at: tmp)
    }
}

private extension URL {

    func withAppComponent() -> URL {
        appending(component: "Calendr.app", directoryHint: .isDirectory)
    }
}
