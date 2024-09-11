//
//  MockEventDetailsSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockEventDetailsSettings: EventDetailsSettings {

    let showMap: Observable<Bool>
    let popoverMaterial: Observable<PopoverMaterial>

    init(showMap: Bool = false, popoverMaterial: PopoverMaterial = .popover) {
        self.showMap = .just(showMap)
        self.popoverMaterial = .just(popoverMaterial)
    }
}

#endif
