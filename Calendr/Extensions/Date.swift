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
}
