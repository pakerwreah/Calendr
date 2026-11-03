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

extension DateProviding {

    // use this instead of `calendar.isDateInToday`, which is unmockable
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }
}

class DateProvider: DateProviding {

    protocol SystemTimeProviding {
        var date: Date { get }
        var calendar: Calendar { get }
    }

    private class SystemTimeProvider: SystemTimeProviding {
        var date: Date { .init() }
        var calendar: Calendar { .current }
    }

    private(set) var calendar: Calendar

    private let system: SystemTimeProviding

    var now: Date { system.date }

    let calendarUpdated: Observable<Calendar>

    private let disposeBag = DisposeBag()
    private let notificationCenter: NotificationCenter
    private let localStorage: LocalStorageProvider

    init(
        notificationCenter: NotificationCenter,
        localStorage: LocalStorageProvider,
        system: SystemTimeProviding = SystemTimeProvider()
    ) {
        self.notificationCenter = notificationCenter
        self.localStorage = localStorage
        self.system = system
        self.calendar = system.calendar

        let calendarSubject = PublishSubject<Calendar>()
        calendarUpdated = calendarSubject.asObservable()

        localStorage
            .rx.observe(\.firstWeekday)
            .repeat(when: Observable.merge(
                notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification).void(),
                notificationCenter.rx.notification(.NSSystemTimeZoneDidChange).void(),
                notificationCenter.rx.notification(.NSCalendarDayChanged).void()
            ))
            .compactMap { [weak self] firstWeekday in
                guard let self else { return nil }
                calendar = system.calendar
                calendar.firstWeekday = firstWeekday
                return calendar
            }
            .bind(to: calendarSubject)
            .disposed(by: disposeBag)
    }
}
