//
//  MockEventDetailsSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockEventDetailsSettings: MockAppearanceSettings, EventDetailsSettings {

    let showMap: Observable<Bool>

    init(showMap: Bool = false) {
        self.showMap = .just(showMap)
    }
}

#endif
