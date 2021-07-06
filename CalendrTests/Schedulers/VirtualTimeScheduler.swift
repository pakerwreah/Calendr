//
//  VirtualTimeScheduler.swift
//  CalendrTests
//
//  Created by Paker on 06/02/21.
//

import Foundation
import RxSwift
@testable import Calendr

extension VirtualTimeScheduler where VirtualTime == RxTime {

    func advance(_ interval: RxTimeInterval) {
        advanceTo(clock + interval.timeInterval)
    }

    func advance(_ value: Int, _ component: Calendar.Component, using calendar: Calendar = .gregorian) {
        advanceTo(calendar.date(byAdding: component, value: value, to: clock)!)
    }
}

extension RxTimeInterval {
    
    var timeInterval: TimeInterval {
        switch self {
        case let .seconds(s):
            return TimeInterval(s)
        case let .milliseconds(ms):
            return TimeInterval(TimeInterval(ms) / 1000.0)
        case let .microseconds(us):
            return TimeInterval(Int64(us)) * TimeInterval(NSEC_PER_USEC) / TimeInterval(NSEC_PER_SEC)
        case let .nanoseconds(ns):
            return TimeInterval(ns) / TimeInterval(NSEC_PER_SEC)
        case .never:
            return .infinity
        @unknown default:
            return .infinity
        }
    }
}
