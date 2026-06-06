//
//  MockScreenProvider.swift
//  CalendrTests
//
//  Created by Paker on 09/04/22.
//

import Foundation
import RxSwift
@testable import Calendr

class MockScreenProvider: ScreenProviding {

    let isLockedObserver: AnyObserver<Bool>
    let isLockedObservable: Observable<Bool>

    let screenObserver: AnyObserver<Screen>
    let screenObservable: Observable<Screen>

    init() {
        (isLockedObservable, isLockedObserver) = BehaviorSubject.pipe(value: false)
        (screenObservable, screenObserver) = BehaviorSubject.pipe(value: MockScreen())
    }
}

