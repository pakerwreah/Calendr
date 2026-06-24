//
//  AutoUpdaterTests.swift
//  CalendrTests
//
//  Created by Paker on 16/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

@MainActor
class AutoUpdaterTests {

    let disposeBag = DisposeBag()

    let launchServices = MockLaunchServiceProvider()
    let localStorage = MockLocalStorageProvider()
    let notificationProvider = MockLocalNotificationProvider()
    let networkProvider = MockNetworkServiceProvider()
    let fileProvider = MockFileProvider()
    let saveModalFactory = MockSaveModalFactory()

    lazy var updater = AutoUpdater(
        launchServices: launchServices,
        localStorage: localStorage,
        notificationProvider: notificationProvider,
        networkProvider: networkProvider,
        fileProvider: fileProvider,
        bundleInfo: .main,
        saveModalFactory: saveModalFactory
    )

    private var tempDirs: [URL] = []

    init() {
        localStorage.reset()
    }

    deinit {
        saveModalFactory.cancel()
        for dir in tempDirs {
            try? FileManager.default.removeItem(at: dir)
        }
        tempDirs.removeAll()
    }

    // MARK: - NotificationAction mapping via notificationTap

    @Test func testNotificationTap_mapsNewVersion_default() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: nil))

        guard case .newVersion(.default) = received else {
            Issue.record("Expected .newVersion(.default), got \(String(describing: received))")
            return
        }
    }

    @Test func testNotificationTap_withNewVersionCategory_install() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: "install"))

        guard case .newVersion(.install) = received else {
            Issue.record("Expected .newVersion(.install), got \(String(describing: received))")
            return
        }
    }

    @Test func testNotificationTap_withUpdatedCategory_shouldTriggerDefaultAction() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .updated, actionId: nil))

        guard case .updated = received else {
            Issue.record("Expected .updated(.default), got \(String(describing: received))")
            return
        }
    }

    @Test func testNotificationTap_mapsNewVersion_unknownActionId() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: "unknown"))

        guard case .newVersion(.default) = received else {
            Issue.record("Expected .newVersion(.default) for unknown action, got \(String(describing: received))")
            return
        }
    }

    // MARK: - Initial status

    @Test func testInitialStatus() {

        var status: UpdateStatus?

        updater.status
            .bind { status = $0 }
            .disposed(by: disposeBag)

        guard case .initial = status else {
            Issue.record("Expected .initial, got \(String(describing: status))")
            return
        }
    }

    // MARK: - checkRelease

    @Test func testCheckRelease_authorizationDenied_shouldNotFetch() async {

        let initialExpectation = expectation(description: "Initial")
        let unexpected = expectation(description: "Unexpected")
        unexpected.isInverted = true

        notificationProvider.m_requestAuthorization = false

        updater.status
            .bind {
                switch $0 {
                    case .initial: initialExpectation.fulfill()
                    default: unexpected.fulfill()
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, unexpected])
    }

    @Test func testCheckRelease_sameVersion_resetsToInitial() async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let rollbackExpectation = expectation(description: "Rollback")

        let version = BuildConfig.appVersion
        let json = makeReleaseJSON(name: version, assetURL: "https://example.com/Calendr.zip")

        networkProvider.m_dataHandler = { _ in json }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, rollbackExpectation])

        #expect(localStorage.lastCheckedVersion == version)
    }

    @Test func testCheckRelease_newVersion_updatesStatus() async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let newVersionExpectation = expectation(description: "New Version")

        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")

        networkProvider.m_dataHandler = { _ in json }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()

                    case (2, .newVersion(let v)):
                        newVersionExpectation.fulfill()
                        #expect(v == "v99.0.0")

                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, newVersionExpectation])
    }

    @Test func testCheckRelease_newVersion_setsLastCheckedVersion() async {

        let newVersionExpectation = expectation(description: "New Version")

        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")

        networkProvider.m_dataHandler = { _ in json }

        updater.status
            .bind {
                if case .newVersion = $0 {
                    newVersionExpectation.fulfill()
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [newVersionExpectation])

        #expect(localStorage.lastCheckedVersion == "v99.0.0")
    }

    @Test func testCheckRelease_missingAsset_reportsError() async {

        let errorExpectation = expectation(description: "Error")

        let json = makeReleaseJSON(name: "v99.0.0", assetName: "Other.zip", assetURL: "https://example.com/Other.zip")

        networkProvider.m_dataHandler = { _ in json }

        var error: UpdateError?

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [errorExpectation])

        guard let error else {
            Issue.record("Expected error")
            return
        }
        guard case .check = error else {
            Issue.record("Unexpected error \(error)")
            return
        }
        #expect(error.title == "Failed to check for update")
        #expect(error.message == "Missing release asset")
    }

    @Test func testCheckRelease_networkError_reportsError() async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let rollbackExpectation = expectation(description: "Rollback")
        let errorExpectation = expectation(description: "Error")

        networkProvider.m_dataHandler = { _ in
            throw UnexpectedError(message: "Network failed")
        }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        var error: UpdateError?

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, rollbackExpectation, errorExpectation])

        guard let error else {
            Issue.record("Expected error")
            return
        }
        guard case .check = error else {
            Issue.record("Unexpected error \(error)")
            return
        }
        #expect(error.title == "Failed to check for update")
        #expect(error.message == "Network failed")
    }

    @Test func testCheckRelease_emptyResponse_reportsError() async {

        await assertCheckRelease_invalidData(Data())
    }

    @Test func testCheckRelease_htmlResponse_reportsError() async {

        await assertCheckRelease_invalidData(Data("<html><body>Not Found</body></html>".utf8))
    }

    private func assertCheckRelease_invalidData(_ data: Data) async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let rollbackExpectation = expectation(description: "Rollback")
        let errorExpectation = expectation(description: "Error")

        networkProvider.m_dataHandler = { _ in data }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        var error: UpdateError?

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, rollbackExpectation, errorExpectation])

        guard case .check = error else {
            Issue.record("Unexpected error \(String(describing: error))")
            return
        }
        #expect(error?.title == "Failed to check for update")
    }

    // MARK: - downloadAndInstall

    @Test func testDownloadAndInstall_withoutRelease_resetsToInitial() async {

        let initialExpectation = expectation(description: "Initial")
        initialExpectation.expectedFulfillmentCount = 2

        updater.status
            .bind {
                switch $0 {
                    case .initial: initialExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.downloadAndInstall()

        await fulfillment(of: [initialExpectation])
    }

    @Test func testDownloadAndInstall_downloadError_reportsError() async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let newVersionExpectation = expectation(description: "New Version")
        let downloadingExpectation = expectation(description: "Downloading")
        let rollbackExpectation = expectation(description: "Rollback")
        let errorExpectation = expectation(description: "Error")

        // First set up a release via checkRelease
        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }

        networkProvider.m_downloadHandler = { _ in
            throw UnexpectedError(message: "Download failed")
        }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .newVersion("v99.0.0")): newVersionExpectation.fulfill()
                    case (3, .downloading("v99.0.0")): downloadingExpectation.fulfill()
                    case (4, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        var error: UpdateError?

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, newVersionExpectation])

        #expect(error == nil)

        updater.downloadAndInstall()

        await fulfillment(of: [downloadingExpectation, errorExpectation, rollbackExpectation])

        guard let error else {
            Issue.record("Expected error")
            return
        }
        guard case .download = error else {
            Issue.record("Unexpected error \(error)")
            return
        }
        #expect(error.title == "Failed to download update")
        #expect(error.message == "Download failed")
    }

    @Test func testDownloadAndInstall_setsDownloadingStatus() async {

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let newVersionExpectation = expectation(description: "New Version")
        let downloadingExpectation = expectation(description: "Downloading")

        let rollbackExpectation = expectation(description: "Rollback")
        rollbackExpectation.isInverted = true

        let errorExpectation = expectation(description: "Error")
        errorExpectation.isInverted = true

        // First set up a release via checkRelease
        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }

        networkProvider.m_downloadHandler = { $0 }

        // hang on the permission prompt so the flow stalls at downloading
        saveModalFactory.hang = true

        // scoped locally so the subscription is released before tearDown cancels the
        // hanging modal, which would otherwise emit a trailing rollback status
        let localBag = DisposeBag()

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .newVersion("v99.0.0")): newVersionExpectation.fulfill()
                    case (3, .downloading("v99.0.0")): downloadingExpectation.fulfill()
                    case (_, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: localBag)

        updater.error
            .bind { _ in
                errorExpectation.fulfill()
            }
            .disposed(by: localBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, newVersionExpectation])

        updater.downloadAndInstall()

        await fulfillment(of: [downloadingExpectation, errorExpectation, rollbackExpectation])
    }

    // MARK: - Installation flow

    @Test func testInstall_permissionDenied_returnsToNewVersion() async {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let newVersionExpectation = expectation(description: "New Version")
        let downloadingExpectation = expectation(description: "Downloading")
        let backToNewVersionExpectation = expectation(description: "Back to New Version")

        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }
        networkProvider.m_downloadHandler = { $0 }

        saveModalFactory.response = .cancel

        var relaunchURL: URL?
        launchServices.didRelaunch = { relaunchURL = $0 }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .newVersion("v99.0.0")): newVersionExpectation.fulfill()
                    case (3, .downloading("v99.0.0")): downloadingExpectation.fulfill()
                    case (4, .newVersion("v99.0.0")): backToNewVersionExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, newVersionExpectation])

        updater.downloadAndInstall()

        await fulfillment(of: [downloadingExpectation, backToNewVersionExpectation])

        #expect(saveModalFactory.spyMakeCalled)
        #expect(relaunchURL == nil)
        #expect(localStorage.updatedVersion == nil)
        #expect(localStorage.installationBookmark == nil)
    }

    @Test func testInstall_permissionGrantedWrongFolder_reportsInstallError() async {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        await primeRelease(updater, version: "v99.0.0")

        networkProvider.m_downloadHandler = { $0 }
        saveModalFactory.response = .OK
        saveModalFactory.url = containerURL.appendingPathComponent("Wrong", isDirectory: true)

        var bookmarkSaved = false
        fileProvider.spyBookmarkData = { _ in bookmarkSaved = true; return Data() }

        var relaunchURL: URL?
        launchServices.didRelaunch = { relaunchURL = $0 }

        var error: UpdateError?
        let errorExpectation = expectation(description: "Error")

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.downloadAndInstall()

        await fulfillment(of: [errorExpectation])

        guard case .install = error else {
            Issue.record("Expected .install error, got \(String(describing: error))")
            return
        }
        #expect(error?.message == Strings.AutoUpdate.Replace.error)
        #expect(bookmarkSaved == false)
        #expect(relaunchURL == nil)
        #expect(localStorage.installationBookmark == nil)
    }

    @Test func testInstall_existingValidBookmark_usesSecurityScope() async {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        await primeRelease(updater, version: "v99.0.0")

        localStorage.installationBookmark = Data([1, 2, 3])

        networkProvider.m_downloadHandler = { $0 }

        fileProvider.spyResolveSecurityScopedURL = { _ in (containerURL, false) }

        var startAccessed = false
        var stopAccessed = false
        fileProvider.spyStartAccessing = { _ in startAccessed = true; return true }
        fileProvider.spyStopAccessing = { _ in stopAccessed = true }

        // fail inside the security scope to short-circuit the archive extraction
        fileProvider.spyTrashItem = { _ in throw UnexpectedError(message: "trash failed") }

        var error: UpdateError?
        let errorExpectation = expectation(description: "Error")

        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.downloadAndInstall()

        await fulfillment(of: [errorExpectation])

        #expect(startAccessed)
        #expect(stopAccessed)
        #expect(saveModalFactory.spyMakeCalled == false)

        guard case .install = error else {
            Issue.record("Expected .install error, got \(String(describing: error))")
            return
        }
        #expect(error?.message == "trash failed")
    }

    @Test func testInstall_replaceAppFails_savesBookmarkAndCleansUp() async {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        let initialExpectation = expectation(description: "Initial")
        let fetchExpectation = expectation(description: "Fetching")
        let newVersionExpectation = expectation(description: "New Version")
        let downloadingExpectation = expectation(description: "Downloading")
        let rollbackExpectation = expectation(description: "Rollback")
        let errorExpectation = expectation(description: "Error")

        let json = makeReleaseJSON(name: "v99.0.0", assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }

        let archiveURL = makeTempDir().appendingPathComponent("Calendr.zip")
        networkProvider.m_downloadHandler = { _ in archiveURL }

        saveModalFactory.response = .OK

        fileProvider.spyBookmarkData = { _ in Data([9, 9]) }
        fileProvider.spyTrashItem = { _ in throw UnexpectedError(message: "trash failed") }

        var removedItem: URL?
        fileProvider.spyRemoveItem = { removedItem = $0 }

        var relaunchURL: URL?
        launchServices.didRelaunch = { relaunchURL = $0 }

        updater.status
            .enumerated()
            .bind {
                switch $0 {
                    case (0, .initial): initialExpectation.fulfill()
                    case (1, .fetching): fetchExpectation.fulfill()
                    case (2, .newVersion("v99.0.0")): newVersionExpectation.fulfill()
                    case (3, .downloading("v99.0.0")): downloadingExpectation.fulfill()
                    case (4, .initial): rollbackExpectation.fulfill()
                    default: Issue.record("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        var error: UpdateError?
        updater.error
            .bind {
                error = $0
                errorExpectation.fulfill()
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        await fulfillment(of: [initialExpectation, fetchExpectation, newVersionExpectation])

        updater.downloadAndInstall()

        await fulfillment(of: [downloadingExpectation, errorExpectation, rollbackExpectation])

        guard case .install = error else {
            Issue.record("Expected .install error, got \(String(describing: error))")
            return
        }
        #expect(localStorage.installationBookmark == Data([9, 9]))
        #expect(removedItem == archiveURL)
        #expect(relaunchURL == nil)
    }

    @Test func testInstall_success_relaunchesAndPersistsVersion() async throws {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        await primeRelease(updater, version: "v99.0.0")

        let archiveURL = try makeAppZip(content: "v99.0.0")
        networkProvider.m_downloadHandler = { _ in archiveURL }

        saveModalFactory.response = .OK
        fileProvider.spyBookmarkData = { _ in Data([5]) }
        fileProvider.spyTrashItem = { _ in }
        fileProvider.spyRemoveItem = { _ in }

        var relaunchURL: URL?
        let relaunchExpectation = expectation(description: "Relaunch")
        launchServices.didRelaunch = {
            relaunchURL = $0
            relaunchExpectation.fulfill()
        }

        updater.downloadAndInstall()

        await fulfillment(of: [relaunchExpectation])

        let appURL = containerURL.appendingPathComponent("Calendr.app", isDirectory: true)
        #expect(relaunchURL == appURL)
        #expect(localStorage.updatedVersion == "v99.0.0")
        #expect(localStorage.installationBookmark == Data([5]))

        let extractedFile = appURL.appendingPathComponent("Contents/Info.plist")
        #expect(FileManager.default.fileExists(atPath: extractedFile.path))
    }

    // MARK: - Updated notification on init

    @Test func testInit_withUpdatedVersion_matchingAppVersion_sendsNotification() async {

        localStorage.updatedVersion = BuildConfig.appVersion

        let expectation = expectation(description: "notification")

        let notificationProvider = MockLocalNotificationProvider()

        notificationProvider.spySendNotification = { _, _ in
            expectation.fulfill()
            return true
        }

        _ = AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .main
        )

        await fulfillment(of: [expectation])

        #expect(localStorage.updatedVersion == nil)
    }

    @Test func testInit_withUpdatedVersion_differentVersion_shouldNotSendNotification() async {

        localStorage.updatedVersion = "v0.0.1"

        let expectation = expectation(description: "notification")
        expectation.isInverted = true

        let notificationProvider = MockLocalNotificationProvider()

        notificationProvider.spySendNotification = { _, _ in
            expectation.fulfill()
            return true
        }

        _ = AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .main
        )

        await fulfillment(of: [expectation])

        #expect(localStorage.updatedVersion == nil)
    }

    @Test func testInit_withoutUpdatedVersion_shouldNotSendNotification() async {

        let expectation = expectation(description: "notification")
        expectation.isInverted = true

        let notificationProvider = MockLocalNotificationProvider()

        notificationProvider.spySendNotification = { _, _ in
            expectation.fulfill()
            return true
        }

        _ = AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .main
        )

        await fulfillment(of: [expectation])
    }

    // MARK: - Notification categories registration

    @Test func testInit_registersNotificationCategories() {

        let notificationProvider = MockLocalNotificationProvider()

        _ = AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .main
        )

        #expect(notificationProvider.spyRegisteredCategories.count == 2)

        let identifiers = notificationProvider.spyRegisteredCategories.map(\.identifier)
        #expect(identifiers.contains(LocalNotification.Category.newVersion.rawValue))
        #expect(identifiers.contains(LocalNotification.Category.updated.rawValue))
    }

    // MARK: - UpdateError properties

    @Test func testUpdateError_check_title() {

        let error = UpdateError.check(UnexpectedError(message: "test"))
        #expect(error.title == Strings.AutoUpdate.Failed.check)
    }

    @Test func testUpdateError_download_title() {

        let error = UpdateError.download(UnexpectedError(message: "test"))
        #expect(error.title == Strings.AutoUpdate.Failed.download)
    }

    @Test func testUpdateError_install_title() {

        let error = UpdateError.install(UnexpectedError(message: "test"))
        #expect(error.title == Strings.AutoUpdate.Failed.install)
    }

    @Test func testUpdateError_message() {

        let error = UpdateError.check(UnexpectedError(message: "Something went wrong"))
        #expect(error.message == "Something went wrong")
    }

    // MARK: - start / stop

    @Test func testStop_cancelsAutoCheck() async {

        let expectation = expectation(description: "cancel")

        var statuses: [UpdateStatus] = []

        updater.status
            .bind { statuses.append($0) }
            .disposed(by: disposeBag)

        // return valid JSON so the cancelled check ends cleanly without a decode error log
        let json = makeReleaseJSON(name: BuildConfig.appVersion, assetURL: "https://example.com/Calendr.zip")

        networkProvider.m_dataHandler = { _ in
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                expectation.fulfill()
            }
            return json
        }

        updater.start()

        DispatchQueue.main.async {
            self.updater.stop()
        }

        await fulfillment(of: [expectation])
    }

    // MARK: - Helpers

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDirs.append(dir)
        return dir
    }

    private func makeInstallUpdater(containerURL: URL) -> AutoUpdater {
        AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .init(
                bundleURL: containerURL.appendingPathComponent("Calendr.app", isDirectory: true),
                bundleIdentifier: "com.test.calendr"
            ),
            saveModalFactory: saveModalFactory
        )
    }

    private func primeRelease(_ updater: AutoUpdater, version: String) async {

        let json = makeReleaseJSON(name: version, assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }

        let newVersionExpectation = expectation(description: "Primed New Version")

        let token = updater.status.subscribe(onNext: {
            if case .newVersion = $0 { newVersionExpectation.fulfill() }
        })

        updater.checkRelease()

        await fulfillment(of: [newVersionExpectation])

        token.dispose()
    }

    /// Builds a real zip containing a `Calendr.app` bundle so the install flow can extract it.
    private func makeAppZip(content: String) throws -> URL {

        let work = makeTempDir()
        let appURL = work.appendingPathComponent("Calendr.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        try Data(content.utf8).write(to: contentsURL.appendingPathComponent("Info.plist"))

        let zipURL = makeTempDir().appendingPathComponent("Calendr.zip")

        var coordinatorError: NSError?
        var copyError: Error?

        NSFileCoordinator().coordinate(readingItemAt: appURL, options: [.forUploading], error: &coordinatorError) { tempZipURL in
            do {
                try FileManager.default.copyItem(at: tempZipURL, to: zipURL)
            } catch {
                copyError = error
            }
        }

        if let coordinatorError { throw coordinatorError }
        if let copyError { throw copyError }

        return zipURL
    }

    private func makeReleaseJSON(name: String, assetName: String = "Calendr.zip", assetURL: String) -> Data {
        """
        {
            "name": "\(name)",
            "assets": [
                {
                    "name": "\(assetName)",
                    "browser_download_url": "\(assetURL)"
                }
            ]
        }
        """.data(using: .utf8)!
    }
}
