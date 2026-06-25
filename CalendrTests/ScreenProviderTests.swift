//
//  ScreenProviderTests.swift
//  Calendr
//
//  Created by Paker on 06/06/2026.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class ScreenProviderTests {

    let notificationCenter = NotificationCenter()
    let distributedNotificationCenter = NotificationCenter()

    let scheduler = HistoricalScheduler()

    let disposeBag = DisposeBag()

    @Test func testScreenChange() {

        let screenProvider = makeScreenProvider()

        var changeCount = 0

        screenProvider.screenObservable.void().bind {
            changeCount += 1
        }.disposed(by: disposeBag)

        #expect(changeCount == 1)

        notificationCenter.post(name: NSWindow.didChangeScreenNotification, object: nil)

        #expect(changeCount == 1)

        scheduler.advance(.milliseconds(1))

        #expect(changeCount == 2)
    }

    @Test func testScreenInit_isLocked() async {

        let screenProvider = makeScreenProvider(isScreenLocked: true)

        let initExpectation = expectation(description: "Init")

        screenProvider.isLockedObservable.bind { isLocked in
            #expect(isLocked)
            initExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        await fulfillment(of: [initExpectation])
    }

    @Test func testScreenInit_isUnlocked() async {

        let screenProvider = makeScreenProvider(isScreenLocked: false)

        let initExpectation = expectation(description: "Init")

        screenProvider.isLockedObservable.bind { isLocked in
            #expect(isLocked == false)
            initExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        await fulfillment(of: [initExpectation])
    }

    @Test func testScreenLock() async {

        let lockExpectation = expectation(description: "Lock")

        let screenProvider = makeScreenProvider(isScreenLocked: false)

        screenProvider.isLockedObservable.skip(1).bind { isLocked in
            #expect(isLocked)
            lockExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        distributedNotificationCenter.post(name: NSScreen.didLockNotification, object: nil)

        await fulfillment(of: [lockExpectation])
    }

    @Test func testScreenUnlock() async {

        let unlockExpectation = expectation(description: "Unlock")

        let screenProvider = makeScreenProvider(isScreenLocked: true)

        screenProvider.isLockedObservable.skip(1).bind { isLocked in
            #expect(isLocked == false)
            unlockExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        distributedNotificationCenter.post(name: NSScreen.didUnlockNotification, object: nil)

        await fulfillment(of: [unlockExpectation])
    }

    @Test func testScreenLock_thenUnlock() async {

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

        await fulfillment(of: [lockExpectation])

        distributedNotificationCenter.post(name: NSScreen.didUnlockNotification, object: nil)

        await fulfillment(of: [unlockExpectation])
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
