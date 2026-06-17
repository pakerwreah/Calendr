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

    let togglePastEvents: AnyObserver<Bool>
    let showPastEvents: Observable<Bool>

    let toggleOverdueReminders: AnyObserver<Bool>
    let showOverdueReminders: Observable<Bool>

    let toggleEventListSummary: AnyObserver<Bool>
    let showEventListSummary: Observable<Bool>

    init(showPastEvents: Bool = true, showOverdueReminders: Bool = true, showAllDayDetails: Bool = true) {
        (self.showPastEvents, togglePastEvents) = BehaviorSubject.pipe(value: showPastEvents)
        (self.showOverdueReminders, toggleOverdueReminders) = BehaviorSubject.pipe(value: showOverdueReminders)
        (showEventListSummary, toggleEventListSummary) = BehaviorSubject.pipe(value: true)

        super.init(showAllDayDetails: showAllDayDetails)
    }
}

#endif
