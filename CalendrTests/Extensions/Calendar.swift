//
//  Calendar.swift
//  CalendrTests
//
//  Created by Paker on 14/02/2021.
//

import Foundation

extension Calendar {

    init(identifier: Calendar.Identifier, timeZone: TimeZone) {
        self.init(identifier: identifier)
    }

    static let reference = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
}
