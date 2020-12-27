//
//  CalendarHeaderViewModel.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import RxSwift

class CalendarHeaderViewModel {

    let titleObservable: Observable<String>

    init(dateObservable: Observable<Date>) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        titleObservable = dateObservable.map(formatter.string(from:))
    }

}
