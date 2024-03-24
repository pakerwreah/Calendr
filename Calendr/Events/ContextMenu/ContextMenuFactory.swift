//
//  ContextMenuFactory.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import Foundation
import RxSwift

enum ContextMenuSource {
    case list
    case details
    case menubar
}

enum ContextCallbackAction: Equatable {
    case event(EventAction)
    case reminder(ReminderAction)
}

enum ContextMenuFactory {

    static func makeViewModel(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        source: ContextMenuSource,
        callback: AnyObserver<ContextCallbackAction>
    ) -> (any ContextMenuViewModel)? {

        switch event.type {
        case .event, .birthday:
            return EventOptionsViewModel(
                event: event,
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                source: source,
                callback: callback.mapObserver { .event($0) }
            )

        case .reminder:
            return ReminderOptionsViewModel(
                event: event,
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                source: source,
                callback: callback.mapObserver { .reminder($0) }
            )
        }
    }
}
