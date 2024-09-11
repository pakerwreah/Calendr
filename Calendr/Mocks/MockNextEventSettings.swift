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
    let eventStatusItemFontSize: Observable<Float>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showItem: Bool = true,
        fontSize: Float = 12,
        checkRange: Int = 10,
        length: Int = 20,
        detectNotch: Bool = false
    ) {
        showEventStatusItem = .just(showItem)
        eventStatusItemFontSize = .just(fontSize)
        eventStatusItemCheckRange = .just(checkRange)
        eventStatusItemLength = .just(length)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
