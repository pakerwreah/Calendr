//
//  MonthSelectorViewModel.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class MonthSelectorViewModel {

    let titleObservable: Observable<String>

    let prevBtnSubject = PublishSubject<Void>()
    let todayBtnSubject = PublishSubject<Void>()
    let nextBtnSubject = PublishSubject<Void>()

    init(dateObservable: Observable<Date>) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM YYYY"
        titleObservable = dateObservable.map(formatter.string(from:))
    }

}
