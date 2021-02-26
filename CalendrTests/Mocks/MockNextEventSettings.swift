//
//  MockNextEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import RxSwift
@testable import Calendr

class MockNextEventSettings: NextEventSettings {

    var toggleStatusItem: AnyObserver<Bool>
    var showEventStatusItem: Observable<Bool>

    init() {
        (showEventStatusItem, toggleStatusItem) = BehaviorSubject.pipe(value: true)
    }
}
