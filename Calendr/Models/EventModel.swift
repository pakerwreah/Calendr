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
}

enum EventStatus {
    case accepted
    case pending
    case maybe
    case unknown
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

    func meta(using dateProvider: DateProviding) -> EventMeta {
        EventMeta(event: self, dateProvider: dateProvider)
    }

    var isPending: Bool { if case .event(.pending) = type { return true } else { return false } }
}
