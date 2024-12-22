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
    let coordinates: Coordinates?
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
    case reminder(completed: Bool)
}

extension EventType {
    var isEvent: Bool { if case .event = self { return true } else { return false } }
    var isBirthday: Bool { self ~= .birthday }
    var isReminder: Bool { if case .reminder = self { return true } else { return false } }
}

extension EventModel {

    func range(using dateProvider: DateProviding, timeZone: TimeZone? = nil) -> DateRange {
        .init(start: start, end: end, timeZone: timeZone, dateProvider: dateProvider)
    }

    func isInProgress(using dateProvider: DateProviding) -> Bool { dateProvider.calendar.isDate(dateProvider.now, in: (start, end), granularity: .second) }

    var status: EventStatus { if case .event(let status) = type { return status } else { return .unknown } }

    var isMeeting: Bool { !participants.isEmpty }

    func calendarAppURL(using dateProvider: DateProviding) -> URL {

        guard !type.isReminder else {
            return URL(string: "x-apple-reminderkit://remcdreminder/\(id)")!
        }

        let date: String
        if hasRecurrenceRules {
            let formatter = DateFormatter(format: "yyyyMMdd'T'HHmmss'Z'", calendar: dateProvider.calendar)
            if !isAllDay {
                formatter.timeZone = .init(secondsFromGMT: 0)
            }
            date = "/\(formatter.string(for: start)!)"
        } else {
            date =  ""
        }
        return URL(string: "ical://ekevent\(date)/\(id)?method=show&options=more")!
    }
}

struct Participant: Hashable {
    let name: String
    let status: EventStatus
    let isOrganizer: Bool
    let isCurrentUser: Bool
}
