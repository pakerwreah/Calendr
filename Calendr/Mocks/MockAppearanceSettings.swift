//
//  MockAppearanceSettings.swift
//  Calendr
//
//  Created by Paker on 13/10/2024.
//

#if DEBUG

import RxSwift

class MockAppearanceSettings: AppearanceSettings {

    let appearanceMode: Observable<AppearanceMode>
    let popoverMaterial: Observable<PopoverMaterial>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>

    init(
        appearanceMode: Observable<AppearanceMode> = .just(.automatic),
        popoverMaterial: Observable<PopoverMaterial> = .just(.popover),
        textScaling: Observable<Double> = .just(1),
        calendarTextScaling: Observable<Double> = .just(1)
    ) {
        self.appearanceMode = appearanceMode
        self.popoverMaterial = popoverMaterial
        self.textScaling = textScaling
        self.calendarTextScaling = calendarTextScaling
    }
}

#endif
