//
//  MockPopoverSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockPopoverSettings: PopoverSettings {

    let popoverMaterial: Observable<PopoverMaterial>

    init(popoverMaterial: PopoverMaterial = .popover) {
        self.popoverMaterial = .just(popoverMaterial)
    }
}

#endif
