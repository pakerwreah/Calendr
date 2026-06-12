//
//  MockNextEventSettings.swift
//  Calendr
//
//  Created by Paker on 07/04/24.
//

#if DEBUG

import RxSwift

class MockNextEventSettings: MockEventListSettings, NextEventSettings {
    let showEventStatusItem: Observable<Bool>
    let eventStatusItemTextScaling: Observable<Double>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemFlashing: Observable<Bool>
    let eventStatusItemSound: Observable<Bool>
    let showFullScreenEvent: Observable<Bool>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>
    let eventStatusItemNotchLength: Observable<Int>

    init(
        showItem: Bool = true,
        checkRange: Int = 10,
        flashing: Bool = true,
        sound: Bool = true,
        fullScreen: Bool = true,
        textScaling: Double = 1,
        length: Int = 20,
        detectNotch: Bool = false,
        notchLength: Int = 10
    ) {
        showEventStatusItem = .just(showItem)
        eventStatusItemCheckRange = .just(checkRange)
        eventStatusItemFlashing = .just(flashing)
        eventStatusItemSound = .just(sound)
        showFullScreenEvent = .just(fullScreen)
        eventStatusItemTextScaling = .just(textScaling)
        eventStatusItemLength = .just(length)
        eventStatusItemDetectNotch = .just(detectNotch)
        eventStatusItemNotchLength = .just(notchLength)
    }
}


#endif
