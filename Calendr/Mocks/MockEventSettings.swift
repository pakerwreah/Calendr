//
//  MockEventSettings.swift
//  Calendr
//
//  Created by Paker on 13/10/2024.
//

#if DEBUG

import RxSwift

class MockEventSettings: MockEventDetailsSettings, EventSettings {

    let showRecurrenceIndicator: Observable<Bool>

    init(showRecurrenceIndicator: Bool = false) {
        self.showRecurrenceIndicator = .just(showRecurrenceIndicator)
    }
}

#endif
