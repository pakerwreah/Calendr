//
//  MockPopoverSettings.swift
//  CalendrTests
//
//  Created by Paker on 25/02/2021.
//

import RxSwift
@testable import Calendr

class MockPopoverSettings: PopoverSettings {

    let popoverMaterial: Observable<PopoverMaterial> = .just(.popover)
}
