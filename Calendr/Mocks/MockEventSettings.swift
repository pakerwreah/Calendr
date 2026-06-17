//
//  MockEventSettings.swift
//  Calendr
//
//  Created by Paker on 05/07/2021.
//

#if DEBUG

import RxSwift

class MockEventSettings: MockAppearanceSettings, EventSettings {

    let toggleRecurrenceIndicator: AnyObserver<Bool>
    let showRecurrenceIndicator: Observable<Bool>

    let toggleForceLocalTimeZone: AnyObserver<Bool>
    let forceLocalTimeZone: Observable<Bool>

    let toggleAllDayEvents: AnyObserver<Bool>
    let showAllDayEvents: Observable<Bool>

    let toggleAllDayDetails: AnyObserver<Bool>
    let showAllDayDetails: Observable<Bool>

    let toggleShowMap: AnyObserver<Bool>
    let showMap: Observable<Bool>

    init(
        showRecurrenceIndicator: Bool = true,
        forceLocalTimeZone: Bool = false,
        showMap: Bool = false,
        showAllDayEvents: Bool = true,
        showAllDayDetails: Bool = true
    ) {
        (self.showRecurrenceIndicator, toggleRecurrenceIndicator) = BehaviorSubject.pipe(value: showRecurrenceIndicator)
        (self.forceLocalTimeZone, toggleForceLocalTimeZone) = BehaviorSubject.pipe(value: forceLocalTimeZone)
        (self.showAllDayEvents, toggleAllDayEvents) = BehaviorSubject.pipe(value: showAllDayEvents)
        (self.showAllDayDetails, toggleAllDayDetails) = BehaviorSubject.pipe(value: showAllDayDetails)
        (self.showMap, toggleShowMap) = BehaviorSubject.pipe(value: showMap)
    }
}

#endif
