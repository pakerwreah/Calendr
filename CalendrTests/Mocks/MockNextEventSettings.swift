//
//  MockNextEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import RxSwift
@testable import Calendr

class MockNextEventSettings: NextEventSettings {

    var toggleStatusItem: AnyObserver<Bool>
    var showEventStatusItem: Observable<Bool>

    var eventStatusItemLengthObserver: AnyObserver<Int>
    var eventStatusItemLength: Observable<Int>

    var toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    var eventStatusItemDetectNotch: Observable<Bool>

    init() {
        (showEventStatusItem, toggleStatusItem) = BehaviorSubject.pipe(value: true)
        (eventStatusItemLength, eventStatusItemLengthObserver) = BehaviorSubject.pipe(value: 18)
        (eventStatusItemDetectNotch, toggleEventStatusItemDetectNotch) = BehaviorSubject.pipe(value: false)
    }
}
