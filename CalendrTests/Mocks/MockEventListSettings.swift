//
//  MockEventListSettings.swift
//  CalendrTests
//
//  Created by Paker on 13/03/2021.
//

import RxSwift
@testable import Calendr

class MockEventListSettings: MockEventSettings, EventListSettings {

    var togglePastEvents: AnyObserver<Bool>
    var showPastEvents: Observable<Bool>

    override init() {
        (showPastEvents, togglePastEvents) = BehaviorSubject.pipe(value: true)
    }
}
