//
//  ContextMenuFactory.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import Foundation

enum ContextMenuSource {
    case list
    case details
    case menubar
}

enum ContextMenuFactory {

    static func makeViewModel(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        source: ContextMenuSource
    ) -> (any ContextMenuViewModel)? {

        switch event.type {
        case .event, .birthday:
            return EventOptionsViewModel(
                event: event,
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                source: source
            )

        case .reminder:
            return ReminderOptionsViewModel(
                event: event,
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                source: source
            )
        }
    }
}
