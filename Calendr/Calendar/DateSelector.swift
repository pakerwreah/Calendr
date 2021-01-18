//
//  DateSelector.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class DateSelector {
    private let dateObservable: Observable<Date>

    init(
        initial: Observable<Date>,
        selected: Observable<Date>,
        reset: Observable<Void>,
        prevDay: Observable<Void>,
        nextDay: Observable<Void>,
        prevWeek: Observable<Void>,
        nextWeek: Observable<Void>,
        prevMonth: Observable<Void>,
        nextMonth: Observable<Void>
    ) {
        var timezone = Calendar.current.timeZone

        dateObservable = Observable.merge(
            initial,
            selected,
            reset.withLatestFrom(initial),
            Observable<(Calendar.Component, Int)>.merge(
                prevDay.map { (.day, -1) },
                nextDay.map { (.day, 1) },
                prevWeek.map { (.weekOfMonth, -1) },
                nextWeek.map { (.weekOfMonth, 1) },
                prevMonth.map { (.month, -1) },
                nextMonth.map { (.month, 1) }
            )
            .withLatestFrom(selected) {
                ($0.0, $0.1, $1)
            }
            .compactMap { component, value, date in
                Calendar.current.date(byAdding: component, value: value, to: date)
            }
        )
        .distinctUntilChanged { a, b in
            timezone == Calendar.current.timeZone && Calendar.current.isDate(a, inSameDayAs: b)
        }
        .do(afterNext: { _ in
            timezone = Calendar.current.timeZone
        })
        .share(replay: 1)
    }

    func asObservable() -> Observable<Date> {
        return dateObservable
    }
}
