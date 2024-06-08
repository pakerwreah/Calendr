//
//  MockNextEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import RxSwift
@testable import Calendr

class MockNextEventSettings: MockPopoverSettings, NextEventSettings {

    let toggleStatusItem: AnyObserver<Bool>
    let showEventStatusItem: Observable<Bool>

    let eventStatusItemFontSizeObserver: AnyObserver<Float>
    let eventStatusItemFontSize: Observable<Float>

    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let eventStatusItemCheckRange: Observable<Int>

    let eventStatusItemLengthObserver: AnyObserver<Int>
    let eventStatusItemLength: Observable<Int>

    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let eventStatusItemDetectNotch: Observable<Bool>

    override init() {
        (showEventStatusItem, toggleStatusItem) = BehaviorSubject.pipe(value: true)
        (eventStatusItemFontSize, eventStatusItemFontSizeObserver) = BehaviorSubject.pipe(value: 12)
        (eventStatusItemCheckRange, eventStatusItemCheckRangeObserver) = BehaviorSubject.pipe(value: 18)
        (eventStatusItemLength, eventStatusItemLengthObserver) = BehaviorSubject.pipe(value: 18)
        (eventStatusItemDetectNotch, toggleEventStatusItemDetectNotch) = BehaviorSubject.pipe(value: false)
        super.init()
    }
}
