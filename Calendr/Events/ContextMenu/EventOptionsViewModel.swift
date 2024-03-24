//
//  EventOptionsViewModel.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

enum EventAction: Equatable {
    case open
    case skip
    case status(EventStatusAction)
}

enum EventStatusAction: Equatable {
    case accept
    case maybe
    case decline
}

class EventOptionsViewModel: BaseContextMenuViewModel<EventAction> {

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    init?(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        source: ContextMenuSource,
        callback: AnyObserver<EventAction>
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace

        super.init(callback: callback)

        if [.list, .menubar].contains(source) {
            addItem(.open)
        }

        if source ~= .menubar {
            addSeparator()
            addItem(.skip)
        }

        if event.status != .unknown {
            addSeparator()

            if event.status != .accepted {
                addItem(.status(.accept))
            }
            if event.status != .maybe {
                addItem(.status(.maybe))
            }
            if event.status != .declined {
                addItem(.status(.decline))
            }
        }

        guard !items.isEmpty else { return nil }
    }

    private func openEvent() {

        let date: String
        if event.hasRecurrenceRules {
            let formatter = DateFormatter(format: "yyyyMMdd'T'HHmmss'Z'", calendar: dateProvider.calendar)
            if !event.isAllDay {
                formatter.timeZone = .init(secondsFromGMT: 0)
            }
            date = "/\(formatter.string(for: event.start)!)"
        } else {
            date =  ""
        }
        workspace.open(URL(string: "ical://ekevent\(date)/\(event.id)?method=show&options=more")!)
    }

    override func onAction(_ action: Action) -> Observable<Void> {

        switch action {
        case .open:
            openEvent()
        case .skip:
            break
        case .status(let action):
            return changeEventStatus(to: action.status)
        }
        return .just(())
    }

    private func changeEventStatus(to status: EventStatus) -> Observable<Void> {
        calendarService.changeEventStatus(id: event.id, date: event.start, to: status)
    }
}

private extension EventStatusAction {

    var status: EventStatus {
        switch self {
        case .accept:
            return .accepted
        case .maybe:
            return .maybe
        case .decline:
            return .declined
        }
    }
}

extension EventAction: ContextMenuAction {

    var icon: NSImage? {
        switch self {
        case .open:
            return Icons.Event.open
        case .skip:
            return Icons.Event.skip
        case .status(.accept):
            return Icons.EventStatus.accepted.with(color: .systemGreen)
        case .status(.maybe):
            return Icons.EventStatus.maybe.with(color: .systemOrange)
        case .status(.decline):
            return Icons.EventStatus.declined.with(color: .systemRed)
        }
    }

    var title: String {
        switch self {
        case .open:
            return Strings.EventAction.open
        case .skip:
            return Strings.EventAction.skip
        case .status(.accept):
            return Strings.EventAction.accept
        case .status(.maybe):
            return Strings.EventAction.maybe
        case .status(.decline):
            return Strings.EventAction.decline
        }
    }
}
