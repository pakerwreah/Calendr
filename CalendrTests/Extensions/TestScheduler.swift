//
//  TestScheduler.swift
//  CalendrTests
//
//  Created by Paker on 06/02/21.
//

import RxSwift

// I hate the default TestScheduler 😠
typealias TestScheduler = HistoricalScheduler

extension TestScheduler {

    func advance(by interval: RxTimeInterval) {
        advanceTo(clock + interval.timeInterval)
    }
}

extension RxTimeInterval {
    // Shamelessly copied from ReactiveSwift 😅
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
