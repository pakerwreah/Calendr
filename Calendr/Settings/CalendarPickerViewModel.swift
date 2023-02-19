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
    let toggleNextEvent: AnyObserver<String>

    // Observables
    let calendars: Observable<[CalendarModel]>
    let showNextEvent: Observable<Bool>
    private(set) lazy var enabledCalendars = selectedObservable(\.enabledCalendars)
    private(set) lazy var nextEventCalendars = selectedObservable(\.nextEventCalendars)

    private let userDefaults: UserDefaults
    private let toggleCalendarSubject = PublishSubject<String>()
    private let toggleNextEventSubject = PublishSubject<String>()
    private let disposeBag = DisposeBag()

    init(
        calendarService: CalendarServiceProviding,
        userDefaults: UserDefaults
    ) {

        self.calendars = calendarService.changeObservable
            .flatMapLatest(calendarService.calendars)
            .distinctUntilChanged()
            .share(replay: 1)

        self.showNextEvent = userDefaults.rx.observe(\.showEventStatusItem)

        self.toggleCalendar = toggleCalendarSubject.asObserver()
        self.toggleNextEvent = toggleNextEventSubject.asObserver()

        self.userDefaults = userDefaults

        setUpBindings()
    }

    private func setUpBindings() {

        setUpBinding(
            subject: toggleCalendarSubject,
            selected: enabledCalendars,
            binder: userDefaults.rx.enabledCalendars
        )

        setUpBinding(
            subject: toggleNextEventSubject,
            selected: nextEventCalendars,
            binder: userDefaults.rx.nextEventCalendars
        )
    }

    private func setUpBinding(
        subject: PublishSubject<String>,
        selected: Observable<[String]>,
        binder: Binder<[String]?>
    ) {
        subject
            .withLatestFrom(selected) { ($0, $1) }
            .map { toggled, identifiers in
                identifiers.contains(toggled)
                    ? identifiers.filter { $0 != toggled }
                    : identifiers + [toggled]
            }
            .bind(to: binder)
            .disposed(by: disposeBag)
    }

    private func selectedObservable(_ keyPath: KeyPath<UserDefaults, [String]?>) -> Observable<[String]> {

        Observable.combineLatest(
            userDefaults.rx.observe(keyPath),
            calendars.map { $0.map(\.identifier) }
        )
        .map { $0?.filter($1.contains) ?? $1 }
        .share(replay: 1)
    }
}
