//
//  EventAlert.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation

enum EventAlert: Equatable, Hashable, CaseIterable {
    case none
    case atTimeOfEvent
    case fiveMinutesBefore
    case tenMinutesBefore
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case oneHourBefore
    case twoHoursBefore
    case oneDayBefore
    case twoDaysBefore

    var relativeOffset: TimeInterval? {
        switch self {
        case .none: nil
        case .atTimeOfEvent: 0
        case .fiveMinutesBefore: -300
        case .tenMinutesBefore: -600
        case .fifteenMinutesBefore: -900
        case .thirtyMinutesBefore: -1800
        case .oneHourBefore: -3600
        case .twoHoursBefore: -7200
        case .oneDayBefore: -86400
        case .twoDaysBefore: -172800
        }
    }

    var title: String {
        switch self {
        case .none: Strings.Event.Editor.Alert.none
        case .atTimeOfEvent: Strings.Event.Editor.Alert.atTime
        case .fiveMinutesBefore: Strings.Event.Editor.Alert._5MinutesBefore
        case .tenMinutesBefore: Strings.Event.Editor.Alert._10MinutesBefore
        case .fifteenMinutesBefore: Strings.Event.Editor.Alert._15MinutesBefore
        case .thirtyMinutesBefore: Strings.Event.Editor.Alert._30MinutesBefore
        case .oneHourBefore: Strings.Event.Editor.Alert._1HourBefore
        case .twoHoursBefore: Strings.Event.Editor.Alert._2HoursBefore
        case .oneDayBefore: Strings.Event.Editor.Alert._1DayBefore
        case .twoDaysBefore: Strings.Event.Editor.Alert._2DaysBefore
        }
    }
}
