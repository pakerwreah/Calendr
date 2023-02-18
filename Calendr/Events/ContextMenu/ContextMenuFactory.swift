//
//  ContextMenuFactory.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import Foundation

enum ContextMenuFactory {

    static func makeViewModel(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding
    ) -> (any ContextMenuViewModel)? {

        switch event.type {
        case .event(let status) where status != .unknown:
            return EventOptionsViewModel(event: event, calendarService: calendarService)

        case .reminder:
            return ReminderOptionsViewModel(event: event, dateProvider: dateProvider, calendarService: calendarService)

        default:
            return nil
        }
    }
}
