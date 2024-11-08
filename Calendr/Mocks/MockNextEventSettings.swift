//
//  MockNextEventSettings.swift
//  Calendr
//
//  Created by Paker on 07/04/24.
//

#if DEBUG

import RxSwift

class MockNextEventSettings: MockEventDetailsSettings, NextEventSettings {

    let showEventStatusItem: Observable<Bool>
    let eventStatusItemTextScaling: Observable<Double>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showItem: Bool = true,
        textScaling: Double = 1,
        checkRange: Int = 10,
        length: Int = 20,
        detectNotch: Bool = false
    ) {
        showEventStatusItem = .just(showItem)
        eventStatusItemTextScaling = .just(textScaling)
        eventStatusItemCheckRange = .just(checkRange)
        eventStatusItemLength = .just(length)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
