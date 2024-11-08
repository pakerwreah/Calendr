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
    let toggleBackground: AnyObserver<Bool>
    let statusItemIconStyleObserver: AnyObserver<StatusItemIconStyle>
    let statusItemDateStyleObserver: AnyObserver<StatusItemDateStyle>
    let statusItemDateFormatObserver: AnyObserver<String>
    let showEventStatusItemObserver: AnyObserver<Bool>

    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let showStatusItemBackground: Observable<Bool>
    let statusItemIconStyle: Observable<StatusItemIconStyle>
    let statusItemDateStyle: Observable<StatusItemDateStyle>
    let statusItemDateFormat: Observable<String>
    let showEventStatusItem: Observable<Bool>
    let statusItemTextScaling: Observable<Double>

    init() {
        (showStatusItemIcon, toggleIcon) = BehaviorSubject.pipe(value: true)
        (showStatusItemDate, toggleDate) = BehaviorSubject.pipe(value: true)
        (showStatusItemBackground, toggleBackground) = BehaviorSubject.pipe(value: false)
        (statusItemIconStyle, statusItemIconStyleObserver) = BehaviorSubject.pipe(value: .calendar)
        (statusItemDateStyle, statusItemDateStyleObserver) = BehaviorSubject.pipe(value: .short)
        (statusItemDateFormat, statusItemDateFormatObserver) = BehaviorSubject.pipe(value: "")
        (showEventStatusItem, showEventStatusItemObserver) = BehaviorSubject.pipe(value: true)
        statusItemTextScaling = .just(1)
    }
}
