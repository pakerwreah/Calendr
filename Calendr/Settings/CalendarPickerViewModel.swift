//
//  CalendarPickerViewModel.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxSwift

class CalendarPickerViewModel {

    let toggleCalendar: AnyObserver<String>
    let enabledCalendars: Observable<[String]>
    let calendars: Observable<[CalendarModel]>

    init(calendarService: CalendarServiceProviding, userDefaults: UserDefaults = .standard) {

        self.calendars = calendarService.authObservable.map {
            calendarService.calendars()
        }.share(replay: 1)

        let initialCalendars = calendars.map { calendars in
            {
                userDefaults
                    .stringArray(forKey: Prefs.enabledCalendars)?
                    .filter($0.contains) ?? $0

            }(calendars.map(\.identifier))
        }.take(1)

        let toggleCalendarSubject = PublishSubject<String>()

        let updatedCalendars = initialCalendars.concatMap { initial in

            toggleCalendarSubject.scan(initial) { identifiers, toggled in

                identifiers.contains(toggled)
                    ? identifiers.filter { $0 != toggled }
                    : identifiers + [toggled]
            }
        }
        .do(onNext: {
            userDefaults.setValue($0, forKey: Prefs.enabledCalendars)
        })

        self.toggleCalendar = toggleCalendarSubject.asObserver()

        self.enabledCalendars = Observable.merge(
            initialCalendars,
            updatedCalendars
        ).share(replay: 1)
    }
}
