//
//  MockScreenProvider.swift
//  CalendrTests
//
//  Created by Paker on 09/04/22.
//

import Foundation
import RxSwift
@testable import Calendr

struct MockScreen: Screen {
    var hasNotch: Bool = false
    let visibleFrame: NSRect = .zero
}

class MockScreenProvider: ScreenProviding {

    let screenObserver: AnyObserver<Screen>
    let screenObservable: Observable<Screen>

    init() {
        (screenObservable, screenObserver) = BehaviorSubject.pipe(value: MockScreen())
    }
}

