//
//  EventModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Foundation

struct EventModel: Equatable {
    let id: String
    let start: Date
    let end: Date
    let title: String
    let location: String?
    let notes: String?
    let url: URL?
    let isAllDay: Bool
    let type: EventType
    let calendar: CalendarModel
    let participants: [Participant]
    let timeZone: TimeZone?
    let hasRecurrenceRules: Bool
}

enum EventStatus: Comparable {
    case accepted
    case maybe
    case pending
    case declined
    case unknown

    private var comparisonValue: Int {
        switch self {
        case .accepted: return 1
        case .maybe: return 2
        case .declined: return 3
        case .pending: return 4
        case .unknown: return 5
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.comparisonValue < rhs.comparisonValue
    }
}

enum EventType: Equatable {
    case event(EventStatus)
    case birthday
    case reminder
}

extension EventType {
    var isEvent: Bool { if case .event = self { return true } else { return false } }
    var isBirthday: Bool { self ~= .birthday }
    var isReminder: Bool { self ~= .reminder }
}

extension EventModel {

    func range(using dateProvider: DateProviding) -> DateRange { .init(start: start, end: end, dateProvider: dateProvider) }

    func isInProgress(using dateProvider: DateProviding) -> Bool { dateProvider.calendar.isDate(dateProvider.now, in: (start, end), granularity: .second) }

    var status: EventStatus { if case .event(let status) = type { return status } else { return .unknown } }

    var isMeeting: Bool { !participants.isEmpty }
}

struct Participant: Hashable {
    let name: String
    let status: EventStatus
    let isOrganizer: Bool
    let isCurrentUser: Bool
}
