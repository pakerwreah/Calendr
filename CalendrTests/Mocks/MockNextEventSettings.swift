//
//  MockNextEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import RxSwift
@testable import Calendr

class MockNextEventSettings: MockEventDetailsSettings, NextEventSettings {

    let toggleStatusItem: AnyObserver<Bool>
    let showEventStatusItem: Observable<Bool>

    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let eventStatusItemCheckRange: Observable<Int>

    let toggleEventStatusItemFlashing: AnyObserver<Bool>
    let eventStatusItemFlashing: Observable<Bool>

    let toggleEventStatusItemSound: AnyObserver<Bool>
    let eventStatusItemSound: Observable<Bool>

    let eventStatusItemLengthObserver: AnyObserver<Int>
    let eventStatusItemLength: Observable<Int>

    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let eventStatusItemDetectNotch: Observable<Bool>

    let eventStatusItemTextScaling: Observable<Double>

    init() {
        (showEventStatusItem, toggleStatusItem) = BehaviorSubject.pipe(value: true)
        (eventStatusItemCheckRange, eventStatusItemCheckRangeObserver) = BehaviorSubject.pipe(value: 18)
        (eventStatusItemFlashing, toggleEventStatusItemFlashing) = BehaviorSubject.pipe(value: false)
        (eventStatusItemSound, toggleEventStatusItemSound) = BehaviorSubject.pipe(value: false)
        (eventStatusItemLength, eventStatusItemLengthObserver) = BehaviorSubject.pipe(value: 18)
        (eventStatusItemDetectNotch, toggleEventStatusItemDetectNotch) = BehaviorSubject.pipe(value: false)
        eventStatusItemTextScaling = .just(1)
        super.init()
    }
}
