//
//  MockStatusItemSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockStatusItemSettings: StatusItemSettings {

    var toggleIcon: AnyObserver<Bool>
    var toggleDate: AnyObserver<Bool>
    var dateStyleObserver: AnyObserver<DateStyle>

    var showStatusItemIcon: Observable<Bool>
    var showStatusItemDate: Observable<Bool>
    var statusItemDateStyle: Observable<DateStyle>

    init() {
        (showStatusItemIcon, toggleIcon) = BehaviorSubject.pipe(value: true)
        (showStatusItemDate, toggleDate) = BehaviorSubject.pipe(value: true)
        (statusItemDateStyle, dateStyleObserver) = BehaviorSubject.pipe(value: .short)
    }
}
