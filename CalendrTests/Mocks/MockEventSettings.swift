//
//  MockEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 13/10/2024.
//

import RxSwift
@testable import Calendr

class MockEventSettings: MockAppearanceSettings, EventSettings {
    let toggleRecurrenceIndicator: AnyObserver<Bool>
    let showRecurrenceIndicator: Observable<Bool>

    let toggleForceLocalTimeZone: AnyObserver<Bool>
    let forceLocalTimeZone: Observable<Bool>

    let showMap: Observable<Bool> = .just(false)

    init() {
        (showRecurrenceIndicator, toggleRecurrenceIndicator) = BehaviorSubject.pipe(value: true)
        (forceLocalTimeZone, toggleForceLocalTimeZone) = BehaviorSubject.pipe(value: false)
    }
}
