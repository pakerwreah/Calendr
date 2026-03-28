//
//  Date.swift
//  Calendr
//
//  Created by Paker on 24/10/2025.
//

import Foundation

extension Date {

    func dateComponents(using dateProvider: DateProviding, calendar identifier: Calendar.Identifier? = nil) -> DateComponents {

        var components = dateProvider.calendar.dateComponents(in: dateProvider.calendar.timeZone, from: self)

        if let identifier {
            components.calendar = Calendar(identifier: identifier).with(timeZone: dateProvider.calendar.timeZone)
        }
        return components
    }
}
