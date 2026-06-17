//
//  AutoUpdaterTests.swift
//  CalendrTests
//
//  Created by Paker on 16/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

@MainActor
class AutoUpdaterTests: XCTestCase {

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

    override func setUp() {
        localStorage.reset()
    }

    override func tearDown() {
        saveModalFactory.cancel()
        for dir in tempDirs {
            try? FileManager.default.removeItem(at: dir)
        }
        tempDirs.removeAll()
    }

    // MARK: - NotificationAction mapping via notificationTap

    func testNotificationTap_mapsNewVersion_default() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: nil))

        guard case .newVersion(.default) = received else {
            XCTFail("Expected .newVersion(.default), got \(String(describing: received))")
            return
        }
    }

    func testNotificationTap_withNewVersionCategory_install() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: "install"))

        guard case .newVersion(.install) = received else {
            XCTFail("Expected .newVersion(.install), got \(String(describing: received))")
            return
        }
    }

    func testNotificationTap_withUpdatedCategory_shouldTriggerDefaultAction() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .updated, actionId: nil))

        guard case .updated(.default) = received else {
            XCTFail("Expected .updated(.default), got \(String(describing: received))")
            return
        }
    }

    func testNotificationTap_mapsNewVersion_unknownActionId() {

        var received: AutoUpdater.NotificationAction?

        updater.notificationTap
            .bind { received = $0 }
            .disposed(by: disposeBag)

        notificationProvider.simulateNotificationTap(.init(category: .newVersion, actionId: "unknown"))

        guard case .newVersion(.default) = received else {
            XCTFail("Expected .newVersion(.default) for unknown action, got \(String(describing: received))")
            return
        }
    }

    // MARK: - Initial status

    func testInitialStatus() {

        var status: UpdateStatus?

        updater.status
            .bind { status = $0 }
            .disposed(by: disposeBag)

        guard case .initial = status else {
            XCTFail("Expected .initial, got \(String(describing: status))")
            return
        }
    }

    // MARK: - checkRelease

    func testCheckRelease_authorizationDenied_shouldNotFetch() {

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

        waitForExpectations(timeout: 0.1)
    }

    func testCheckRelease_sameVersion_resetsToInitial() {

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
                    default: XCTFail("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(localStorage.lastCheckedVersion, version)
    }

    func testCheckRelease_newVersion_updatesStatus() {

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
                        XCTAssertEqual(v, "v99.0.0")

                    default: XCTFail("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        waitForExpectations(timeout: 0.1)
    }

    func testCheckRelease_newVersion_setsLastCheckedVersion() {

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

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(localStorage.lastCheckedVersion, "v99.0.0")
    }

    func testCheckRelease_missingAsset_reportsError() {

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

        waitForExpectations(timeout: 0.1)

        guard let error else {
            XCTFail("Expected error")
            return
        }
        guard case .check = error else {
            XCTFail("Unexpected error \(error)")
            return
        }
        XCTAssertEqual(error.title, "Failed to check for update")
        XCTAssertEqual(error.message, "Missing release asset")
    }

    func testCheckRelease_networkError_reportsError() {

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
                    default: XCTFail("Unexpected status: \($0)")
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

        waitForExpectations(timeout: 0.1)

        guard let error else {
            XCTFail("Expected error")
            return
        }
        guard case .check = error else {
            XCTFail("Unexpected error \(error)")
            return
        }
        XCTAssertEqual(error.title, "Failed to check for update")
        XCTAssertEqual(error.message, "Network failed")
    }

    func testCheckRelease_emptyResponse_reportsError() {

        assertCheckRelease_invalidData(Data())
    }

    func testCheckRelease_htmlResponse_reportsError() {

        assertCheckRelease_invalidData(Data("<html><body>Not Found</body></html>".utf8))
    }

    private func assertCheckRelease_invalidData(_ data: Data) {

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
                    default: XCTFail("Unexpected status: \($0)")
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

        waitForExpectations(timeout: 0.1)

        guard case .check = error else {
            XCTFail("Unexpected error \(String(describing: error))")
            return
        }
        XCTAssertEqual(error?.title, "Failed to check for update")
    }

    // MARK: - downloadAndInstall

    func testDownloadAndInstall_withoutRelease_resetsToInitial() {

        let initialExpectation = expectation(description: "Initial")
        initialExpectation.expectedFulfillmentCount = 2

        updater.status
            .bind {
                switch $0 {
                    case .initial: initialExpectation.fulfill()
                    default: XCTFail("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.downloadAndInstall()

        waitForExpectations(timeout: 0.1)
    }

    func testDownloadAndInstall_downloadError_reportsError() {

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
                    default: XCTFail("Unexpected status: \($0)")
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

        wait(for: [initialExpectation, fetchExpectation, newVersionExpectation], timeout: 0.1)

        XCTAssertNil(error)

        updater.downloadAndInstall()

        wait(for: [downloadingExpectation, errorExpectation, rollbackExpectation], timeout: 0.1)

        guard let error else {
            XCTFail("Expected error")
            return
        }
        guard case .download = error else {
            XCTFail("Unexpected error \(error)")
            return
        }
        XCTAssertEqual(error.title, "Failed to download update")
        XCTAssertEqual(error.message, "Download failed")
    }

    func testDownloadAndInstall_setsDownloadingStatus() {

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
                    default: XCTFail("Unexpected status: \($0)")
                }
            }
            .disposed(by: localBag)

        updater.error
            .bind { _ in
                errorExpectation.fulfill()
            }
            .disposed(by: localBag)

        updater.checkRelease()

        wait(for: [initialExpectation, fetchExpectation, newVersionExpectation], timeout: 0.1)

        updater.downloadAndInstall()

        wait(for: [downloadingExpectation, errorExpectation, rollbackExpectation], timeout: 0.1)
    }

    // MARK: - Installation flow

    func testInstall_permissionDenied_returnsToNewVersion() {

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
                    default: XCTFail("Unexpected status: \($0)")
                }
            }
            .disposed(by: disposeBag)

        updater.checkRelease()

        wait(for: [initialExpectation, fetchExpectation, newVersionExpectation], timeout: 0.1)

        updater.downloadAndInstall()

        wait(for: [downloadingExpectation, backToNewVersionExpectation], timeout: 0.1)

        XCTAssertTrue(saveModalFactory.spyMakeCalled)
        XCTAssertNil(relaunchURL)
        XCTAssertNil(localStorage.updatedVersion)
        XCTAssertNil(localStorage.installationBookmark)
    }

    func testInstall_permissionGrantedWrongFolder_reportsInstallError() {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        primeRelease(updater, version: "v99.0.0")

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

        wait(for: [errorExpectation], timeout: 0.1)

        guard case .install = error else {
            XCTFail("Expected .install error, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(error?.message, Strings.AutoUpdate.Replace.error)
        XCTAssertFalse(bookmarkSaved)
        XCTAssertNil(relaunchURL)
        XCTAssertNil(localStorage.installationBookmark)
    }

    func testInstall_existingValidBookmark_usesSecurityScope() {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        primeRelease(updater, version: "v99.0.0")

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

        wait(for: [errorExpectation], timeout: 0.1)

        XCTAssertTrue(startAccessed)
        XCTAssertTrue(stopAccessed)
        XCTAssertFalse(saveModalFactory.spyMakeCalled)

        guard case .install = error else {
            XCTFail("Expected .install error, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(error?.message, "trash failed")
    }

    func testInstall_replaceAppFails_savesBookmarkAndCleansUp() {

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
                    default: XCTFail("Unexpected status: \($0)")
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

        wait(for: [initialExpectation, fetchExpectation, newVersionExpectation], timeout: 0.1)

        updater.downloadAndInstall()

        wait(for: [downloadingExpectation, errorExpectation, rollbackExpectation], timeout: 0.1)

        guard case .install = error else {
            XCTFail("Expected .install error, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(localStorage.installationBookmark, Data([9, 9]))
        XCTAssertEqual(removedItem, archiveURL)
        XCTAssertNil(relaunchURL)
    }

    func testInstall_success_relaunchesAndPersistsVersion() throws {

        let containerURL = makeTempDir()
        let updater = makeInstallUpdater(containerURL: containerURL)

        primeRelease(updater, version: "v99.0.0")

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

        wait(for: [relaunchExpectation], timeout: 0.1)

        let appURL = containerURL.appendingPathComponent("Calendr.app", isDirectory: true)
        XCTAssertEqual(relaunchURL, appURL)
        XCTAssertEqual(localStorage.updatedVersion, "v99.0.0")
        XCTAssertEqual(localStorage.installationBookmark, Data([5]))

        let extractedFile = appURL.appendingPathComponent("Contents/Info.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedFile.path))
    }

    // MARK: - Updated notification on init

    func testInit_withUpdatedVersion_matchingAppVersion_sendsNotification() {

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

        waitForExpectations(timeout: 0.1)

        XCTAssertNil(localStorage.updatedVersion)
    }

    func testInit_withUpdatedVersion_differentVersion_shouldNotSendNotification() {

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

        waitForExpectations(timeout: 0.1)

        XCTAssertNil(localStorage.updatedVersion)
    }

    func testInit_withoutUpdatedVersion_shouldNotSendNotification() {

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

        waitForExpectations(timeout: 0.1)
    }

    // MARK: - Notification categories registration

    func testInit_registersNotificationCategories() {

        let notificationProvider = MockLocalNotificationProvider()

        _ = AutoUpdater(
            launchServices: launchServices,
            localStorage: localStorage,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileProvider: fileProvider,
            bundleInfo: .main
        )

        XCTAssertEqual(notificationProvider.spyRegisteredCategories.count, 2)

        let identifiers = notificationProvider.spyRegisteredCategories.map(\.identifier)
        XCTAssertTrue(identifiers.contains(LocalNotification.Category.newVersion.rawValue))
        XCTAssertTrue(identifiers.contains(LocalNotification.Category.updated.rawValue))
    }

    // MARK: - UpdateError properties

    func testUpdateError_check_title() {

        let error = UpdateError.check(UnexpectedError(message: "test"))
        XCTAssertEqual(error.title, Strings.AutoUpdate.Failed.check)
    }

    func testUpdateError_download_title() {

        let error = UpdateError.download(UnexpectedError(message: "test"))
        XCTAssertEqual(error.title, Strings.AutoUpdate.Failed.download)
    }

    func testUpdateError_install_title() {

        let error = UpdateError.install(UnexpectedError(message: "test"))
        XCTAssertEqual(error.title, Strings.AutoUpdate.Failed.install)
    }

    func testUpdateError_message() {

        let error = UpdateError.check(UnexpectedError(message: "Something went wrong"))
        XCTAssertEqual(error.message, "Something went wrong")
    }

    // MARK: - start / stop

    func testStop_cancelsAutoCheck() {

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

        waitForExpectations(timeout: 0.1)
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

    private func primeRelease(_ updater: AutoUpdater, version: String) {

        let json = makeReleaseJSON(name: version, assetURL: "https://example.com/Calendr.zip")
        networkProvider.m_dataHandler = { _ in json }

        let newVersionExpectation = expectation(description: "Primed New Version")

        let token = updater.status.subscribe(onNext: {
            if case .newVersion = $0 { newVersionExpectation.fulfill() }
        })

        updater.checkRelease()

        wait(for: [newVersionExpectation], timeout: 0.1)

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
