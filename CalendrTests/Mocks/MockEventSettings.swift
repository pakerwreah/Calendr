//
//  MockEventSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockEventSettings: EventSettings {

    let popoverMaterial: Observable<PopoverMaterial> = .just(.popover)
}
