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
    let eventStatusItemFlashing: Observable<Bool>
    let eventStatusItemSound: Observable<Bool>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showItem: Bool = true,
        checkRange: Int = 10,
        flashing: Bool = true,
        sound: Bool = true,
        textScaling: Double = 1,
        length: Int = 20,
        detectNotch: Bool = false
    ) {
        showEventStatusItem = .just(showItem)
        eventStatusItemCheckRange = .just(checkRange)
        eventStatusItemFlashing = .just(flashing)
        eventStatusItemSound = .just(sound)
        eventStatusItemTextScaling = .just(textScaling)
        eventStatusItemLength = .just(length)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
