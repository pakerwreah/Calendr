//
//  MockNextEventSettings.swift
//  Calendr
//
//  Created by Paker on 07/04/24.
//

#if DEBUG

import RxSwift

class MockNextEventSettings: MockEventListSettings, NextEventSettings {

    let toggleStatusItem: AnyObserver<Bool>
    let showEventStatusItem: Observable<Bool>

    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let eventStatusItemCheckRange: Observable<Int>

    let toggleEventStatusItemFlashing: AnyObserver<Bool>
    let eventStatusItemFlashing: Observable<Bool>

    let toggleEventStatusItemSound: AnyObserver<Bool>
    let eventStatusItemSound: Observable<Bool>

    let toggleFullScreenEvent: AnyObserver<Bool>
    let showFullScreenEvent: Observable<Bool>

    let eventStatusItemLengthObserver: AnyObserver<Int>
    let eventStatusItemLength: Observable<Int>

    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let eventStatusItemDetectNotch: Observable<Bool>

    let eventStatusItemNotchLengthObserver: AnyObserver<Int>
    let eventStatusItemNotchLength: Observable<Int>

    let eventStatusItemTextScaling: Observable<Double>

    init(
        showItem: Bool = true,
        checkRange: Int = 18,
        flashing: Bool = false,
        sound: Bool = false,
        fullScreen: Bool = false,
        textScaling: Double = 1,
        length: Int = 18,
        detectNotch: Bool = false,
        notchLength: Int = 6,
        showPastEvents: Bool = true,
        showOverdueReminders: Bool = true,
        showAllDayDetails: Bool = true
    ) {
        (showEventStatusItem, toggleStatusItem) = BehaviorSubject.pipe(value: showItem)
        (eventStatusItemCheckRange, eventStatusItemCheckRangeObserver) = BehaviorSubject.pipe(value: checkRange)
        (eventStatusItemFlashing, toggleEventStatusItemFlashing) = BehaviorSubject.pipe(value: flashing)
        (eventStatusItemSound, toggleEventStatusItemSound) = BehaviorSubject.pipe(value: sound)
        (showFullScreenEvent, toggleFullScreenEvent) = BehaviorSubject.pipe(value: fullScreen)
        (eventStatusItemLength, eventStatusItemLengthObserver) = BehaviorSubject.pipe(value: length)
        (eventStatusItemDetectNotch, toggleEventStatusItemDetectNotch) = BehaviorSubject.pipe(value: detectNotch)
        (eventStatusItemNotchLength, eventStatusItemNotchLengthObserver) = BehaviorSubject.pipe(value: notchLength)
        eventStatusItemTextScaling = .just(textScaling)

        super.init(
            showPastEvents: showPastEvents,
            showOverdueReminders: showOverdueReminders,
            showAllDayDetails: showAllDayDetails
        )
    }
}

#endif
