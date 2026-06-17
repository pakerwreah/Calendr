//
//  ScreenProvider.swift
//  Calendr
//
//  Created by Paker on 09/04/22.
//

import AppKit.NSScreen
import RxSwift

protocol Screen {
    var hasNotch: Bool { get }
    var visibleFrame: NSRect { get }
}

protocol ScreenProviding {
    var isLockedObservable: Observable<Bool> { get }
    var screenObservable: Observable<Screen> { get }
}

class ScreenProvider: ScreenProviding {

    let isLockedObservable: Observable<Bool>
    let screenObservable: Observable<Screen>

    private let disposeBag = DisposeBag()

    init(
        notificationCenter: NotificationCenter,
        distributedNotificationCenter: NotificationCenter,
        scheduler: SchedulerType,
        isScreenLocked: Bool = isScreenLocked()
    ) {

        isLockedObservable = Observable
            .merge(
                distributedNotificationCenter.rx.notification(NSScreen.didLockNotification).map(true),
                distributedNotificationCenter.rx.notification(NSScreen.didUnlockNotification).map(false)
            )
            .startWith(isScreenLocked)
            .distinctUntilChanged()
            .share(replay: 1)

        // keep the observable updated
        isLockedObservable.bind {
            if !BuildConfig.isTesting {
                print("Screen is", $0 ? "locked" : "unlocked")
            }
        }.disposed(by: disposeBag)

        screenObservable = notificationCenter.rx.notification(NSWindow.didChangeScreenNotification)
            .debounce(.milliseconds(1), scheduler: scheduler)
            .void()
            .startWith(())
            .compactMap { NSScreen.main }
            .share(replay: 1)
    }
}

extension ScreenProviding {

    var hasNotchObservable: Observable<Bool> {
        screenObservable
            .map(\.hasNotch)
            .distinctUntilChanged()
    }
}

extension NSScreen: Screen {

    var hasNotch: Bool { auxiliaryTopRightArea != nil }

    static let didLockNotification = NSNotification.Name("com.apple.screenIsLocked")
    static let didUnlockNotification = NSNotification.Name("com.apple.screenIsUnlocked")
}

private func isScreenLocked() -> Bool {
    guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else {
        return false
    }
    return session["CGSSessionScreenIsLocked"] as? Bool ?? false
}
