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
    var screenObservable: Observable<Screen> { get }
}

class ScreenProvider: ScreenProviding {

    let screenObservable: Observable<Screen>

    init(notificationCenter: NotificationCenter) {

        screenObservable = notificationCenter.rx.notification(NSWindow.didChangeScreenNotification)
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

    var hasNotch: Bool {
        guard #available(macOS 12, *) else { return false }
        return auxiliaryTopRightArea != nil
    }
}
