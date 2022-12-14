//
//  CalendarPickerViewModel.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Foundation
import RxSwift

class CalendarPickerViewModel {

    // Observers
    let toggleCalendar: AnyObserver<String>

    // Observables
    let calendars: Observable<[CalendarModel]>
    let enabledCalendars: Observable<[String]>

    private let userDefaults: UserDefaults
    private let toggleCalendarSubject = PublishSubject<String>()
    private let disposeBag = DisposeBag()

    init(
        calendarService: CalendarServiceProviding,
        userDefaults: UserDefaults
    ) {

        self.calendars = calendarService.changeObservable
            .flatMapLatest(calendarService.calendars)
            .distinctUntilChanged()
            .share(replay: 1)

        self.toggleCalendar = toggleCalendarSubject.asObserver()

        self.enabledCalendars = Observable.combineLatest(
            calendars, userDefaults.rx.observe(\.enabledCalendars)
        )
        .map { calendars, enabled in
            let identifiers = calendars.map(\.identifier)
            guard let enabled = enabled else { return identifiers }
            return enabled.filter(identifiers.contains)
        }
        .share(replay: 1)

        self.userDefaults = userDefaults

        setUpBindings()
    }

    private func setUpBindings() {

        toggleCalendarSubject
            .withLatestFrom(enabledCalendars) { ($0, $1) }
            .map { toggled, identifiers in
                identifiers.contains(toggled)
                    ? identifiers.filter { $0 != toggled }
                    : identifiers + [toggled]
            }
            .bind(to: userDefaults.rx.enabledCalendars)
            .disposed(by: disposeBag)
    }
}
