//
//  MockEventListSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

class MockEventListSettings: MockEventSettings, EventListSettings {

    let showPastEvents: Observable<Bool>
    let showOverdueReminders: Observable<Bool>

    init(showPastEvents: Bool = true, showOverdueReminders: Bool = true) {
        self.showPastEvents = .just(showPastEvents)
        self.showOverdueReminders = .just(showOverdueReminders)
    }
}

#endif
