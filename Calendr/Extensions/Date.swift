//
//  Date.swift
//  Calendr
//
//  Created by Paker on 24/10/2025.
//


extension Date {

    func dateComponents(using dateProvider: DateProviding) -> DateComponents {
        dateProvider.calendar.dateComponents(in: dateProvider.calendar.timeZone, from: self)
    }
}
