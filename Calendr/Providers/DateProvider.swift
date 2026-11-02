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
        scheduler: SchedulerType = WallTimeScheduler.instance,
        system: SystemTimeProviding = SystemTimeProvider()
    ) {
        self.notificationCenter = notificationCenter
        self.localStorage = localStorage
        self.system = system
        self.calendar = system.calendar

        let calendarSubject = PublishSubject<Calendar>()
        calendarUpdated = calendarSubject.asObservable()

        // The system only posts `NSCalendarDayChanged` at its own midnight, so post it at the custom one.
        // Subscribed first because the pipeline below emits the initial calendar synchronously.
        calendarSubject
            .flatMapLatest { calendar -> Observable<Void> in
                let now = system.date
                guard
                    calendar.timeZone != system.calendar.timeZone,
                    let midnight = calendar.nextDate(
                        after: now,
                        matching: DateComponents(hour: 0, minute: 0, second: 0),
                        matchingPolicy: .nextTime
                    )
                else { return .empty() }
                let delay = Int(now.distance(to: midnight).rounded(.up))
                return Observable<Int>.timer(.seconds(delay), scheduler: scheduler).void()
            }
            .bind { notificationCenter.post(name: .NSCalendarDayChanged, object: nil) }
            .disposed(by: disposeBag)

        Observable
            .combineLatest(
                localStorage.rx.observe(\.firstWeekday),
                localStorage.rx.observe(\.timeZone)
            )
            .repeat(when: Observable.merge(
                notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification).void(),
                notificationCenter.rx.notification(.NSSystemTimeZoneDidChange).void(),
                notificationCenter.rx.notification(.NSCalendarDayChanged).void()
            ))
            .compactMap { [weak self] firstWeekday, timeZone in
                guard let self else { return nil }
                let timeZone = TimeZone(identifier: timeZone) ?? system.calendar.timeZone
                calendar = system.calendar.with(timeZone: timeZone)
                calendar.firstWeekday = firstWeekday
                return calendar
            }
            .bind(to: calendarSubject)
            .disposed(by: disposeBag)
    }
}
