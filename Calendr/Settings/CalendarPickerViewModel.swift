//
//  CalendarPickerViewModel.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Foundation
import RxSwift
import RxRelay

class CalendarPickerViewModel {

    // Observers
    let toggleCalendar: AnyObserver<String>

    // Observables
    let calendars: Observable<[CalendarModel]>
    let enabledCalendars: Observable<[String]>
    let popoverMaterial: Observable<PopoverMaterial>

    init(calendarService: CalendarServiceProviding, userDefaults: UserDefaults, settings: PopoverSettings) {

        self.calendars = calendarService.changeObservable
            .flatMapLatest(calendarService.calendars)
            .share(replay: 1)

        let toggleCalendarSubject = PublishRelay<String>()

        self.toggleCalendar = toggleCalendarSubject.asObserver()

        self.enabledCalendars = calendars.map { calendars in
            {
                userDefaults
                    .stringArray(forKey: Prefs.enabledCalendars)?
                    .filter($0.contains) ?? $0

            }(calendars.map(\.identifier))
        }
        .flatMapLatest { initial in

            toggleCalendarSubject.scan(initial) { identifiers, toggled in

                identifiers.contains(toggled)
                    ? identifiers.filter { $0 != toggled }
                    : identifiers + [toggled]
            }
            .startWith(initial)
        }
        .do(onNext: {
            userDefaults.setValue($0, forKey: Prefs.enabledCalendars)
        })
        .share(replay: 1)

        self.popoverMaterial = settings.popoverMaterial
    }
}
