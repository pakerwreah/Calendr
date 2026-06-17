//
//  MockScreenProvider.swift
//  Calendr
//
//  Created by Paker on 22/07/23.
//

#if DEBUG

import Foundation
import RxSwift

struct MockScreen: Screen {
    var hasNotch: Bool = false
    let visibleFrame: NSRect = .zero
}

class MockScreenProvider: ScreenProviding {

    let isLockedObserver: AnyObserver<Bool>
    let isLockedObservable: Observable<Bool>

    let screenObserver: AnyObserver<Screen>
    let screenObservable: Observable<Screen>

    init(screen: Screen = MockScreen()) {
        (isLockedObservable, isLockedObserver) = BehaviorSubject.pipe(value: false)
        (screenObservable, screenObserver) = BehaviorSubject.pipe(value: screen)
    }
}

#endif
