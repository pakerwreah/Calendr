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

    private(set) lazy var enabledCalendars = selectedObservable(notIn: \.disabledCalendars)
    private(set) lazy var nextEventCalendars = selectedObservable(notIn: \.silencedCalendars)

    private let userDefaults: UserDefaults
    private let toggleCalendarSubject = PublishSubject<String>()
    private let toggleNextEventSubject = PublishSubject<String>()
    private let disposeBag = DisposeBag()

    init(
        calendarService: CalendarServiceProviding,
        userDefaults: UserDefaults
    ) {

        self.calendars = calendarService.changeObservable
            .startWith(())
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
            current: userDefaults.rx.observe(\.disabledCalendars),
            binder: userDefaults.rx.disabledCalendars
        )

        setUpBinding(
            subject: toggleNextEventSubject,
            current: userDefaults.rx.observe(\.silencedCalendars),
            binder: userDefaults.rx.silencedCalendars
        )

        calendars
            .filter(\.isEmpty.isFalse)
            .map { $0.map(\.id) }
            .bind { [userDefaults] calendars in
                // clean up removed calendars
                userDefaults.disabledCalendars = userDefaults.disabledCalendars.filter(calendars.contains)
                userDefaults.silencedCalendars = userDefaults.silencedCalendars.filter(calendars.contains)
            }
            .disposed(by: disposeBag)
    }

    private func setUpBinding(
        subject: PublishSubject<String>,
        current: Observable<[String]>,
        binder: Binder<[String]>
    ) {
        subject
            .withLatestFrom(current) { ($0, $1) }
            .map { toggled, identifiers in
                identifiers.contains(toggled)
                    ? identifiers.filter { $0 != toggled }
                    : identifiers + [toggled]
            }
            .bind(to: binder)
            .disposed(by: disposeBag)
    }

    private func selectedObservable(notIn keyPath: KeyPath<UserDefaults, [String]>) -> Observable<[String]> {

        Observable.combineLatest(
            userDefaults.rx.observe(keyPath),
            calendars.map { $0.map(\.id) }
        )
        .map { unselected, calendars in
            calendars.filter { !unselected.contains($0) }
        }
        .share(replay: 1)
    }
}
