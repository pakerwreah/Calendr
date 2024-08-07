//
//  DateProvider.swift
//  Calendr
//
//  Created by Paker on 12/01/21.
//

import Foundation
import RxSwift

protocol DateProviding: AnyObject {
    var calendar: Calendar { get }
    var now: Date { get }
    
    var calendarUpdated: Observable<Calendar> { get }
}

class DateProvider: DateProviding {
    private(set) var calendar: Calendar = .current
    var now: Date { Date() }
    
    let calendarUpdated: Observable<Calendar>

    private let disposeBag = DisposeBag()
    private let notificationCenter: NotificationCenter
    private let userDefaults: UserDefaults

    init(notificationCenter: NotificationCenter, userDefaults: UserDefaults) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults

        let calendarSubject = PublishSubject<Calendar>()
        calendarUpdated = calendarSubject.asObservable()

        userDefaults.rx
            .observe(\.firstWeekday)
            .repeat(when: Observable.merge(
                notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification).void(),
                notificationCenter.rx.notification(.NSSystemTimeZoneDidChange).void(),
                notificationCenter.rx.notification(.NSCalendarDayChanged).void()
            ))
            .compactMap { [weak self] firstWeekday in
                guard let self else { return nil }
                calendar = .current
                calendar.firstWeekday = firstWeekday
                return calendar
            }
            .bind(to: calendarSubject)
            .disposed(by: disposeBag)
    }
}
