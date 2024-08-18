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

protocol AutoUpdating {
    func start()
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

    enum NotificationAction: String {
        case `default`
        case install

        static func from(rawValue: String) -> Self {
            return .init(rawValue: rawValue) ?? .default
        }
    }

    private enum NotificationCategory {

        static let update = UNNotificationCategory(
            categoryId: "update",
            actionId: NotificationAction.install.rawValue,
            title: Strings.AutoUpdate.install
        )
    }

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

    private let userDefaults: UserDefaults
    private(set) var notificationProvider: LocalNotificationProviding
    private let networkProvider: NetworkServiceProviding
    private let fileManager: FileManager

    init(
        userDefaults: UserDefaults,
        notificationProvider: LocalNotificationProviding,
        networkProvider: NetworkServiceProviding,
        fileManager: FileManager
    ) {
        self.userDefaults = userDefaults
        self.notificationProvider = notificationProvider
        self.networkProvider = networkProvider
        self.fileManager = fileManager

        (newVersionAvailable, newVersionAvailableObserver) = PublishSubject.pipe(scheduler: MainScheduler.instance)

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
                ) { _ in
                    self.checkRelease(notify: true)
                }
            }
        }
    }

    func checkRelease(notify: Bool) {
        Task {
            do {
                try await checkRelease(notify)
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
        Task {
            await notificationProvider.register(category: NotificationCategory.update)
        }
    }

    private func checkRelease(_ notify: Bool) async throws {

        guard !BuildConfig.isUITesting else { return }

        newVersionAvailableObserver.onNext(.fetching)

        let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
        let data = try await networkProvider.data(from: URL(string: url)!)
        let release = try JSONDecoder().decode(Release.self, from: data)

        guard release.name != "v\(BuildConfig.appVersion)" else {
            newVersionAvailableObserver.onNext(.initial)
            userDefaults.lastCheckedVersion = release.name
            return
        }

        newRelease = release
        newVersionAvailableObserver.onNext(.newVersion(release.name))

        guard notify else {
            userDefaults.lastCheckedVersion = release.name
            return
        }

        guard release.name != userDefaults.lastCheckedVersion else {
            return // only notify each version once
        }

        await sendNotification(version: release.name)
    }

    private func sendNotification(version: String) async {

        let content = UNMutableNotificationContent()
        content.title = Strings.AutoUpdate.newVersion(version)
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.update.identifier

        if await notificationProvider.send(id: .uuid, content) {
            userDefaults.lastCheckedVersion = version
        }
    }

    private func downloadAndInstall() async throws {
        guard
            let release = newRelease,
            let url = newRelease?.assets.first(where: { $0.name == "Calendr.zip" })?.browser_download_url
        else {
            throw UnexpectedError(message: "Missing asset url?")
        }

        newVersionAvailableObserver.onNext(.downloading(release.name))

        let appUrl = Bundle.main.bundleURL

        let archiveURL = try await networkProvider.download(from: url)

        defer { try? fileManager.removeItem(at: archiveURL) }

        try await replaceApp(url: appUrl, archive: archiveURL)

        try relaunchApp(url: appUrl)
    }

    private func replaceApp(url appUrl: URL, archive archiveURL: URL) async throws {

        let url: URL? = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                NSApp.modalWindow?.close()
                let dialog = NSSavePanel()
                dialog.directoryURL = appUrl.deletingLastPathComponent()
                dialog.nameFieldStringValue = appUrl.lastPathComponent
                dialog.nameFieldLabel = "Calendr.app"
                dialog.prompt = "Install"
                dialog.title = "Please don't change anything"
                dialog.message = "Confirm the app location so we have permission to replace it"
                dialog.begin { result in
                    continuation.resume(returning: dialog.url)
                }
            }
        }

        guard url == appUrl else {
            throw UnexpectedError(message: "Failed to install app")
        }

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
        task.arguments = [url.path, "--args", "-updated"]
        try task.run()

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
