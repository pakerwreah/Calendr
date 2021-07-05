//
//  MockEventListSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import Foundation
import RxSwift

struct MockEventListSettings: EventListSettings {

    let showPastEvents: Observable<Bool>
    let popoverMaterial: Observable<PopoverMaterial>

    init(showPastEvents: Bool = true, popoverMaterial: PopoverMaterial = .popover) {
        self.showPastEvents = .just(showPastEvents)
        self.popoverMaterial = .just(popoverMaterial)
    }
}

#endif
