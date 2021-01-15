//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxSwift

class SettingsViewModel {

    let enabledCalendarsObserver: AnyObserver<[String]>
    let enabledCalendarsObservable: Observable<[String]>
    let calendars: Observable<[CalendarModel]>

    init(calendarService: CalendarServiceProviding, userDefaults: UserDefaults) {

        // FIXME: Remove startWith
        calendars = calendarService.changeObservable.startWith(()).map {
            calendarService.calendars
        }.share(replay: 1)

        let enabledCalendarsSubject = PublishSubject<[String]>()

        enabledCalendarsObserver = enabledCalendarsSubject.asObserver()

        let initCalendars = calendars.map {
            userDefaults.stringArray(forKey: "enabled_calendars") ?? $0.map(\.identifier)
        }.take(1)

        let enabledCalendars = enabledCalendarsSubject.do(onNext: {
            userDefaults.setValue($0, forKey: "enabled_calendars")
        })

        enabledCalendarsObservable = Observable.merge(
            initCalendars,
            enabledCalendars
        ).share(replay: 1)
    }
}
