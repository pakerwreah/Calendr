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
    let distributedNotificationCenter = DistributedNotificationCenter()

    let scheduler = HistoricalScheduler()

    let disposeBag = DisposeBag()

    lazy var screenProvider = ScreenProvider(
        notificationCenter: notificationCenter,
        distributedNotificationCenter: distributedNotificationCenter,
        scheduler: scheduler
    )

    func testScreenChange() {

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

    func testScreenLockInit_shouldBeUnlocked() {

        let initExpectation = expectation(description: "Init")
        var isLocked: Bool?

        screenProvider.isLockedObservable.bind {
            isLocked = $0
            initExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        wait(for: [initExpectation], timeout: 0.1)

        XCTAssertEqual(isLocked, false)
    }

    func testScreenLocked_thenUnlocked() {
        let lockExpectation = expectation(description: "Lock")
        let unlockExpectation = expectation(description: "Unlock")

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
}
