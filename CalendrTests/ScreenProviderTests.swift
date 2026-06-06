//
//  ScreenProviderTests.swift
//  Calendr
//
//  Created by Paker on 06/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class ScreenProviderTests: XCTestCase {

    let notificationCenter = NotificationCenter()
    let distributedNotificationCenter = NotificationCenter()

    let scheduler = HistoricalScheduler()

    let disposeBag = DisposeBag()

    func testScreenChange() {

        let screenProvider = makeScreenProvider()

        var changeCount = 0

        screenProvider.screenObservable.void().bind {
            changeCount += 1
        }.disposed(by: disposeBag)

        XCTAssertEqual(changeCount, 1)

        notificationCenter.post(name: NSWindow.didChangeScreenNotification, object: nil)

        XCTAssertEqual(changeCount, 1)

        scheduler.advance(.milliseconds(1))

        XCTAssertEqual(changeCount, 2)
    }

    func testScreenInit_isLocked() {

        let screenProvider = makeScreenProvider(isScreenLocked: true)

        let initExpectation = expectation(description: "Init")

        screenProvider.isLockedObservable.bind { isLocked in
            XCTAssertTrue(isLocked)
            initExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        wait(for: [initExpectation], timeout: 0.1)
    }

    func testScreenInit_isUnlocked() {

        let screenProvider = makeScreenProvider(isScreenLocked: false)

        let initExpectation = expectation(description: "Init")

        screenProvider.isLockedObservable.bind { isLocked in
            XCTAssertFalse(isLocked)
            initExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        wait(for: [initExpectation], timeout: 0.1)
    }

    func testScreenLock() {

        let lockExpectation = expectation(description: "Lock")

        let screenProvider = makeScreenProvider(isScreenLocked: false)

        screenProvider.isLockedObservable.skip(1).bind { isLocked in
            XCTAssertTrue(isLocked)
            lockExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        distributedNotificationCenter.post(name: NSScreen.didLockNotification, object: nil)

        wait(for: [lockExpectation], timeout: 0.1)
    }

    func testScreenUnlock() {

        let unlockExpectation = expectation(description: "Unlock")

        let screenProvider = makeScreenProvider(isScreenLocked: true)

        screenProvider.isLockedObservable.skip(1).bind { isLocked in
            XCTAssertFalse(isLocked)
            unlockExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        distributedNotificationCenter.post(name: NSScreen.didUnlockNotification, object: nil)

        wait(for: [unlockExpectation], timeout: 0.1)
    }

    func testScreenLock_thenUnlock() {

        let lockExpectation = expectation(description: "Lock")
        let unlockExpectation = expectation(description: "Unlock")

        let screenProvider = makeScreenProvider(isScreenLocked: false)

        screenProvider.isLockedObservable.skip(1).bind { isLocked in
            if isLocked {
                lockExpectation.fulfill()
            } else {
                unlockExpectation.fulfill()
            }
        }
        .disposed(by: disposeBag)

        distributedNotificationCenter.post(name: NSScreen.didLockNotification, object: nil)

        wait(for: [lockExpectation], timeout: 0.1)

        distributedNotificationCenter.post(name: NSScreen.didUnlockNotification, object: nil)

        wait(for: [unlockExpectation], timeout: 0.1)
    }

    // MARK: - Factory

    private func makeScreenProvider(isScreenLocked: Bool = false) -> ScreenProviding {
        ScreenProvider(
            notificationCenter: notificationCenter,
            distributedNotificationCenter: distributedNotificationCenter,
            scheduler: scheduler,
            isScreenLocked: isScreenLocked
        )
    }
}
