//
//  Date.swift
//  Calendr
//
//  Created by Paker on 24/10/2025.
//

import Foundation

extension Date {

    func components(using dateProvider: DateProviding, calendar identifier: Calendar.Identifier? = nil) -> DateComponents {

        let calendarToUse: Calendar

        if let identifier {
            calendarToUse = Calendar(identifier: identifier).with(timeZone: dateProvider.calendar.timeZone)
        } else {
            calendarToUse = dateProvider.calendar
        }

        return calendarToUse.dateComponents(in: calendarToUse.timeZone, from: self)
    }

    func start(of component: Calendar.Component, using dateProvider: DateProviding) -> Self {

        guard
            let result = dateProvider.calendar.dateInterval(of: component, for: self)?.start
        else {
            print("🔥 Could not truncate date \(self) to \(component)")
            return self
        }

        return result
    }

    func adding(_ components: DateComponents, using dateProvider: DateProviding) -> Self {

        guard
            let result = dateProvider.calendar.date(byAdding: components, to: self)
        else {
            print("🔥 Could not calculate date by adding \(components) to \(self)")
            return self
        }
        return result
    }

    func withCurrentTime(using dateProvider: DateProviding) -> Self {

        let date = dateProvider.calendar.startOfDay(for: self)
        let time = dateProvider.calendar.dateComponents([.hour, .minute, .second], from: dateProvider.now)

        guard
            let result = dateProvider.calendar.date(byAdding: time, to: date)
        else {
            print("🔥 Could not calculate date by adding \(time) to \(self)")
            return self
        }

        return result
    }

    func rounded(toNext component: Calendar.Component, using dateProvider: DateProviding) -> Self {

        let calendar = dateProvider.calendar

        guard
            let interval = calendar.dateInterval(of: component, for: self),
            let result = calendar.date(byAdding: component, value: 1, to: interval.start)
        else {
            print("🔥 Could not calculate date \(self) rounded to next \(component)")
            return self
        }
        return result
    }
}
