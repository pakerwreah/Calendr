//
//  MockEventListSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

class MockEventListSettings: MockPopoverSettings, EventListSettings {

    let showPastEvents: Observable<Bool>

    init(showPastEvents: Bool = true, popoverMaterial: PopoverMaterial = .popover) {
        self.showPastEvents = .just(showPastEvents)
    }
}

#endif
