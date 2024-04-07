//
//  MockNextEventSettings.swift
//  Calendr
//
//  Created by Paker on 07/04/24.
//

#if DEBUG

import RxSwift

class MockNextEventSettings: MockPopoverSettings, NextEventSettings {

    let showEventStatusItem: Observable<Bool>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showItem: Bool = true,
        checkRange: Int = 10,
        length: Int = 20,
        detectNotch: Bool = false
    ) {
        showEventStatusItem = .just(showItem)
        eventStatusItemCheckRange = .just(checkRange)
        eventStatusItemLength = .just(length)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
