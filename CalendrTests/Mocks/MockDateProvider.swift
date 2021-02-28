//
//  MockDateProvider.swift
//  CalendrTests
//
//  Created by Paker on 30/01/21.
//

import Foundation
@testable import Calendr

class MockDateProvider: DateProviding {
    var m_calendar = Calendar.reference
    var calendar: Calendar { m_calendar }
    var now: Date = .make(year: 2021, month: 1, day: 1)

    func add(_ value: Int, _ component: Calendar.Component) {
        now = calendar.date(byAdding: component, value: value, to: now)!
    }
}
