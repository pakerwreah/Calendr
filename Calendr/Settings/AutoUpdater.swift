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

protocol AutoUpdating {
    @MainActor func start()
    func checkRelease(notify: Bool)
    func downloadAndInstall()
}

class AutoUpdater: AutoUpdating {

    enum CheckUpdateStatus {
        case initial
        case fetching
        case newVersion(String)
        case downloading(String)
    }

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

    private let newVersionAvailableObserver: AnyObserver<CheckUpdateStatus>
    let newVersionAvailable: Observable<CheckUpdateStatus>

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

        (newVersionAvailable, newVersionAvailableObserver) = BehaviorSubject.pipe(value: .initial, on: MainScheduler.instance)

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

    func checkRelease(notify: Bool) {
        Task {
            do {
                try await checkReleaseAsync(notify: notify)
            } catch {
                newVersionAvailableObserver.onNext(.initial)
                print(error.localizedDescription)
            }
        }
    }

    func downloadAndInstall() {
        Task {
            do {
                try await downloadAndInstall()
            } catch {
                newVersionAvailableObserver.onNext(.initial)
                print("Failed to update the app: \(error.localizedDescription)")
            }
        }
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

        newVersionAvailableObserver.onNext(.fetching)

        let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
        let data = try await networkProvider.data(from: URL(string: url)!)
        let release = try JSONDecoder().decode(Release.self, from: data)

        guard release.name != BuildConfig.appVersion else {
            newVersionAvailableObserver.onNext(.initial)
            localStorage.lastCheckedVersion = release.name
            return
        }

        newRelease = release
        newVersionAvailableObserver.onNext(.newVersion(release.name))

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

    private func getAppUrl() -> URL {
        let appUrl = Bundle.main.bundleURL
        /// gatekeeper might go nuts if you restore the app from the trash 🔮
        guard appUrl.pathComponents.contains("AppTranslocation"), let applications = getApplicationsUrl() else {
            return appUrl
        }
        return applications.appendingPathComponent("Calendr.app", conformingTo: .directory)
    }

    private func downloadAndInstall() async throws {
        guard
            let release = newRelease,
            let url = newRelease?.assets.first(where: { $0.name == "Calendr.zip" })?.browser_download_url
        else {
            throw UnexpectedError(message: "Missing asset url?")
        }

        newVersionAvailableObserver.onNext(.downloading(release.name))

        let appUrl = getAppUrl()

        let archiveURL = try await networkProvider.download(from: url)

        defer { try? fileManager.removeItem(at: archiveURL) }

        let selectedURL = try await savePanel(for: appUrl)

        try await replaceApp(url: selectedURL, archive: archiveURL)

        localStorage.updatedVersion = release.name

        try relaunchApp(url: selectedURL)
    }

    private func savePanel(for appUrl: URL) async throws -> URL {

        let selectedURL = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                NSApp.modalWindow?.close()
                let dialog = NSSavePanel()
                dialog.directoryURL = appUrl.deletingLastPathComponent()
                dialog.nameFieldStringValue = appUrl.lastPathComponent
                dialog.nameFieldLabel = "Calendr.app"
                dialog.prompt = Strings.AutoUpdate.install
                dialog.message = Strings.AutoUpdate.Replace.message
                dialog.begin { result in
                    continuation.resume(returning: result == .cancel ? nil : dialog.url)
                }
            }
        }
        guard let selectedURL else {
            throw UnexpectedError(message: "User canceled the save panel")
        }
        return selectedURL
    }

    private func replaceApp(url appUrl: URL, archive archiveURL: URL) async throws {

        try fileManager.trashItem(at: appUrl, resultingItemURL: nil)

        let archive = try Archive(url: archiveURL, accessMode: .read)

        for entry in archive where entry.path.starts(with: "Calendr.app/") {
            let entryURL = appUrl.deletingLastPathComponent().appendingPathComponent(entry.path)
            _ = try archive.extract(entry, to: entryURL)
        }
    }

    private func cleanUpDownloads() {
        try? fileManager.removeItem(at: fileManager.temporaryDirectory)
    }

    private func relaunchApp(url: URL) throws {

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [url.path]
        try task.run()

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
