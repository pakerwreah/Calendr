//
//  DateSelector.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class DateSelector {
    private let dateObservable: Observable<Date>

    init(initial: Observable<Date>,
         reset: Observable<Void> = .empty(),
         prevDay: Observable<Void> = .empty(),
         nextDay: Observable<Void> = .empty(),
         prevWeek: Observable<Void> = .empty(),
         nextWeek: Observable<Void> = .empty(),
         prevMonth: Observable<Void> = .empty(),
         nextMonth: Observable<Void> = .empty()) {

        let calendar = Calendar.current

        dateObservable = Observable.merge(
            reset.map { Date() },
            Observable<(Calendar.Component, Int)>.merge(
                prevDay.map { (.day, -1) },
                nextDay.map { (.day, 1) },
                prevWeek.map { (.weekOfMonth, -1) },
                nextWeek.map { (.weekOfMonth, 1) },
                prevMonth.map { (.month, -1) },
                nextMonth.map { (.month, 1) }
            )
            .withLatestFrom(initial) {
                ($0.0, $0.1, $1)
            }
            .compactMap { component, value, date in
                calendar.date(byAdding: component, value: value, to: date)
            }
        )
    }

    func asObservable() -> Observable<Date> {
        return dateObservable
    }
}
