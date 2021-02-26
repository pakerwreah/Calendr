//
//  MockEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockEventSettings: EventSettings {

    var togglePastEvents: AnyObserver<Bool>
    var showPastEvents: Observable<Bool>

    init() {
        (showPastEvents, togglePastEvents) = BehaviorSubject.pipe(value: true)
    }
}
