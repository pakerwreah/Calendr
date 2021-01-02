//
//  DateSelector.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class DateSelector {
    private let selectedSubject = PublishSubject<Date>()
    private lazy var dateObservable = selectedSubject.asObservable()

    private let disposeBag = DisposeBag()

    init(initial: Observable<Date>,
         reset: Observable<Void>,
         prevDay: Observable<Void>,
         nextDay: Observable<Void>,
         prevWeek: Observable<Void>,
         nextWeek: Observable<Void>,
         prevMonth: Observable<Void>,
         nextMonth: Observable<Void>) {

        Observable.merge(
            initial,
            reset.withLatestFrom(initial),
            Observable<(Calendar.Component, Int)>.merge(
                prevDay.map { (.day, -1) },
                nextDay.map { (.day, 1) },
                prevWeek.map { (.weekOfMonth, -1) },
                nextWeek.map { (.weekOfMonth, 1) },
                prevMonth.map { (.month, -1) },
                nextMonth.map { (.month, 1) }
            )
            .withLatestFrom(dateObservable) {
                ($0.0, $0.1, $1)
            }
            .compactMap { component, value, date in
                Calendar.current.date(byAdding: component, value: value, to: date)
            }
        )
        .distinctUntilChanged { a, b in
            Calendar.current.isDate(a, inSameDayAs: b)
        }
        .bind(to: selectedSubject)
        .disposed(by: disposeBag)
    }

    func asObservable() -> Observable<Date> {
        return dateObservable
    }
}
