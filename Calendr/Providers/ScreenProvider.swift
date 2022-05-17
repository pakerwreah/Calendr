//
//  ScreenProvider.swift
//  Calendr
//
//  Created by Paker on 09/04/22.
//

import AppKit.NSScreen
import RxSwift

protocol ScreenProviding {
    var hasNotchObservable: Observable<Bool> { get }
}

class ScreenProvider: ScreenProviding {

    private static var hasNotch: Bool {
        guard #available(macOS 12, *) else { return false }
        return NSScreen.main?.auxiliaryTopRightArea != nil
    }

    let hasNotchObservable: Observable<Bool>

    init(notificationCenter: NotificationCenter) {

        hasNotchObservable = notificationCenter.rx.notification(NSWindow.didChangeScreenNotification)
            .void()
            .startWith(())
            .map { Self.hasNotch }
            .distinctUntilChanged()
    }
}
