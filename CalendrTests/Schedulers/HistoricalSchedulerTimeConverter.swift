//
//  HistoricalSchedulerTimeConverter.swift
//  CalendrTests
//
//  Created by Paker on 08/03/2021.
//
// 💡 This is just a copy from RxSwift because it doesn't have a public constructor ¯\_(ツ)_/¯
//

import RxSwift

/// Converts historical virtual time into real time.
///
/// Since historical virtual time is also measured in `Date`, this converter is identity function.
public struct HistoricalSchedulerTimeConverter : VirtualTimeConverterType {
    /// Virtual time unit used that represents ticks of virtual clock.
    public typealias VirtualTimeUnit = RxTime

    /// Virtual time unit used to represent differences of virtual times.
    public typealias VirtualTimeIntervalUnit = TimeInterval

    /// Returns identical value of argument passed because historical virtual time is equal to real time, just
    /// decoupled from local machine clock.
    public func convertFromVirtualTime(_ virtualTime: VirtualTimeUnit) -> RxTime {
        virtualTime
    }

    /// Returns identical value of argument passed because historical virtual time is equal to real time, just
    /// decoupled from local machine clock.
    public func convertToVirtualTime(_ time: RxTime) -> VirtualTimeUnit {
        time
    }

    /// Returns identical value of argument passed because historical virtual time is equal to real time, just
    /// decoupled from local machine clock.
    public func convertFromVirtualTimeInterval(_ virtualTimeInterval: VirtualTimeIntervalUnit) -> TimeInterval {
        virtualTimeInterval
    }

    /// Returns identical value of argument passed because historical virtual time is equal to real time, just
    /// decoupled from local machine clock.
    public func convertToVirtualTimeInterval(_ timeInterval: TimeInterval) -> VirtualTimeIntervalUnit {
        timeInterval
    }

    /**
     Offsets `Date` by time interval.

     - parameter time: Time.
     - parameter timeInterval: Time interval offset.
     - returns: Time offsetted by time interval.
    */
    public func offsetVirtualTime(_ time: VirtualTimeUnit, offset: VirtualTimeIntervalUnit) -> VirtualTimeUnit {
        time.addingTimeInterval(offset)
    }

    /// Compares two `Date`s.
    public func compareVirtualTime(_ lhs: VirtualTimeUnit, _ rhs: VirtualTimeUnit) -> VirtualTimeComparison {
        switch lhs.compare(rhs as Date) {
        case .orderedAscending:
            return .lessThan
        case .orderedSame:
            return .equal
        case .orderedDescending:
            return .greaterThan
        }
    }
}
