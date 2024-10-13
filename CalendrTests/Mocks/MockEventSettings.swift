//
//  MockEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 13/10/2024.
//

import RxSwift
@testable import Calendr

class MockEventSettings: MockEventDetailsSettings, EventSettings {

    let toggleRecurrenceIndicator: AnyObserver<Bool>
    let showRecurrenceIndicator: Observable<Bool>

    init() {
        (showRecurrenceIndicator, toggleRecurrenceIndicator) = BehaviorSubject.pipe(value: true)
    }
}
