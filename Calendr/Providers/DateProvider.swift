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
}

class DateProvider: DateProviding {
    let calendar: Calendar
    var now: Date { Date() }

    init(calendar: Calendar) {
        self.calendar = calendar
    }
}

extension DateProviding {

    func calendarObservable(using notificationCenter: NotificationCenter) -> Observable<Calendar> {

        notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()
            .startWith(())
            .compactMap { [weak self] in self?.calendar }
    }
}
