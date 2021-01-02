//
//  CalendarHeaderViewModel.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class CalendarHeaderViewModel {

    // Input
    let prevBtnObserver: AnyObserver<Void>
    let resetBtnObserver: AnyObserver<Void>
    let nextBtnObserver: AnyObserver<Void>

    // Output
    let prevBtnObservable: Observable<Void>
    let resetBtnObservable: Observable<Void>
    let nextBtnObservable: Observable<Void>

    let titleObservable: Observable<String>

    init(dateObservable: Observable<Date>) {
        let formatter = DateFormatter(format: "MMM yyyy")

        titleObservable = dateObservable.map(formatter.string(from:))

        (prevBtnObserver, prevBtnObservable) = PublishSubject<Void>.pipe()
        (resetBtnObserver, resetBtnObservable) = PublishSubject<Void>.pipe()
        (nextBtnObserver, nextBtnObservable) = PublishSubject<Void>.pipe()
    }

}
