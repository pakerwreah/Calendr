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

    let screenObservable: Observable<Screen>

    init(screen: Screen = MockScreen()) {
        screenObservable = .just(screen)
    }
}

#endif
