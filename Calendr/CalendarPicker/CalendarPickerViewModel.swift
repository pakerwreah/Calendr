//
//  CalendarPickerViewModel.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxSwift

class CalendarPickerViewModel {

    // Observers
    let toggleCalendar: AnyObserver<String>

    // Observables
    let calendars: Observable<[CalendarModel]>
    let enabledCalendars: Observable<[String]>

    init(calendarService: CalendarServiceProviding, userDefaults: UserDefaults = .standard) {

        self.calendars = calendarService.changeObservable
            .map(calendarService.calendars)
            .share(replay: 1)

        let toggleCalendarSubject = PublishSubject<String>()

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
    }
}
