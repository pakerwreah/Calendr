//
//  Date.swift
//  Calendr
//
//  Created by Paker on 24/10/2025.
//

import Foundation

extension Date {

    func dateComponents(using dateProvider: DateProviding, calendar identifier: Calendar.Identifier? = nil) -> DateComponents {

        let calendarToUse: Calendar

        if let identifier {
            calendarToUse = Calendar(identifier: identifier).with(timeZone: dateProvider.calendar.timeZone)
        } else {
            calendarToUse = dateProvider.calendar
        }

        return calendarToUse.dateComponents(in: calendarToUse.timeZone, from: self)
    }

    func withCurrentTime(
        adding increment: DateComponents = .init(),
        using dateProvider: DateProviding
    ) -> Self {

        let calendar = dateProvider.calendar
        let currentTime = calendar.dateComponents([.hour, .minute], from: dateProvider.now)

        guard
            let hour = currentTime.hour,
            let minute = currentTime.minute,
            let combined = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: self),
            let result = calendar.date(byAdding: increment, to: combined)
        else {
            print("🔥 Could not calculate date with current time")
            return self
        }

        return result
    }
}
