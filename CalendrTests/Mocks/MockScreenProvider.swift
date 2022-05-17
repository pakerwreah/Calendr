//
//  MockScreenProvider.swift
//  CalendrTests
//
//  Created by Paker on 09/04/22.
//

import RxSwift
@testable import Calendr

class MockScreenProvider: ScreenProviding {

    var hasNotchObserver: AnyObserver<Bool>
    var hasNotchObservable: Observable<Bool>

    init() {
        (hasNotchObservable, hasNotchObserver) = BehaviorSubject.pipe(value: false)
    }
}

