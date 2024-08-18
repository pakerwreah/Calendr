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

class AutoUpdater: NSObject, UNUserNotificationCenterDelegate {

    struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
        }
        let name: String
        let assets: [Asset]
    }

    enum CheckUpdateStatus {
        case initial
        case fetching
        case newVersion(Release)
        case downloading(Release)
    }

    private let notificationTapObserver: AnyObserver<Void>
    let notificationTap: Observable<Void>

    private let newVersionAvailableObserver: AnyObserver<CheckUpdateStatus>
    let newVersionAvailable: Observable<CheckUpdateStatus>

    private var newRelease: Release?

    private let userDefaults: UserDefaults
    private(set) var notificationProvider: LocalNotificationProviding

    init(
        userDefaults: UserDefaults,
        notificationProvider: LocalNotificationProviding
    ) {
        self.userDefaults = userDefaults
        self.notificationProvider = notificationProvider

        (newVersionAvailable, newVersionAvailableObserver) = PublishSubject.pipe(scheduler: MainScheduler.instance)
        (notificationTap, notificationTapObserver) = PublishSubject.pipe(scheduler: MainScheduler.instance)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        notificationTapObserver.onNext(())
    }

    func start() {

        guard !BuildConfig.isUITesting, !BuildConfig.isDebug else { return }

        notificationProvider.delegate = self
        notificationProvider.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            guard granted else { return }
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

    func downloadAndInstall() async {
        do {
            guard
                let release = newRelease,
                let url = newRelease?.assets.first(where: { $0.name == "Calendr.zip" })?.browser_download_url
            else {
                throw UnexpectedError(message: "Missing asset url?")
            }

            newVersionAvailableObserver.onNext(.downloading(release))

            let fileManager = FileManager.default
            let appUrl = Bundle.main.bundleURL

            let (archiveURL, _) = try await URLSession.shared.download(for: URLRequest(url: url))

            try await replaceApp(url: appUrl, archive: archiveURL)

            try relaunchApp(url: appUrl)
        } catch {
            newVersionAvailableObserver.onNext(.initial)
            print("Failed to update the app: \(error.localizedDescription)")
        }
    }

    func checkRelease(notify: Bool) {

        guard !BuildConfig.isUITesting else { return }

        newVersionAvailableObserver.onNext(.fetching)

        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            do {
                try checkReleaseSync(notify)
            } catch {
                newVersionAvailableObserver.onNext(.initial)
                print(error.localizedDescription)
            }
        }
    }

    private func checkReleaseSync(_ notify: Bool) throws {

        let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
        let data = try Data(contentsOf: URL(string: url)!)
        let release = try JSONDecoder().decode(Release.self, from: data)

        guard release.name != "v\(BuildConfig.appVersion)" else {
            newVersionAvailableObserver.onNext(.initial)
            userDefaults.lastCheckedVersion = release.name
            return
        }

        newRelease = release
        newVersionAvailableObserver.onNext(.newVersion(release))

        guard notify else {
            userDefaults.lastCheckedVersion = release.name
            return
        }

        guard release.name != userDefaults.lastCheckedVersion else {
            return // only notify each version once
        }

        sendNotification(version: release.name)
    }

    private func sendNotification(version: String) {
        
        let content = UNMutableNotificationContent()
        content.title = Strings.newVersion(version)
        content.sound = .default

        notificationProvider.add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        ) { [userDefaults] error in
            if let error {
                print(error.localizedDescription)
                return
            }
            userDefaults.lastCheckedVersion = version
        }
    }
}

private func replaceApp(url appUrl: URL, archive archiveURL: URL) async throws {

    let fileManager = FileManager.default

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

private func relaunchApp(url: URL) throws {

    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [url.path]
    try task.run()

    DispatchQueue.main.async {
        NSApp.terminate(nil)
    }
}
