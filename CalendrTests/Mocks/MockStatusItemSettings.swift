//
//  MockStatusItemSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockStatusItemSettings: StatusItemSettings {

    let toggleIcon: AnyObserver<Bool>
    let toggleDate: AnyObserver<Bool>
    let dateStyleObserver: AnyObserver<DateStyle>
    let dateFormatObserver: AnyObserver<String>
    let eventStatusItemDetectNotchObserver: AnyObserver<Bool>

    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let statusItemDateStyle: Observable<DateStyle>
    let statusItemDateFormat: Observable<String>
    let eventStatusItemDetectNotch: Observable<Bool>

    init() {
        (showStatusItemIcon, toggleIcon) = BehaviorSubject.pipe(value: true)
        (showStatusItemDate, toggleDate) = BehaviorSubject.pipe(value: true)
        (statusItemDateStyle, dateStyleObserver) = BehaviorSubject.pipe(value: .short)
        (statusItemDateFormat, dateFormatObserver) = BehaviorSubject.pipe(value: "")
        (eventStatusItemDetectNotch, eventStatusItemDetectNotchObserver) = BehaviorSubject.pipe(value: true)
    }
}
