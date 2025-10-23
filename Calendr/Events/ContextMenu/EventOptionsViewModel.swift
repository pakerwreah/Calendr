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
    case link(EventLink, isInProgress: Bool)
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

            if let link = event.detectLink(using: workspace) {
                addSeparator()
                addItem(.link(link, isInProgress: event.isInProgress(using: dateProvider)))
            }
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

    override func onAction(_ action: Action) -> Completable {

        switch action {
        case .open:
            workspace.open(event)
        case .link(let link, _):
            workspace.open(link)
        case .skip:
            break
        case .status(let action):
            return changeEventStatus(to: action.status)
        }
        return .empty()
    }

    private func changeEventStatus(to status: EventStatus) -> Completable {
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
            return Icons.Calendar.calendar

        case .link(let link, let isInProgress):
            let icon = if link.isMeeting {
                isInProgress ? Icons.Event.video_fill : Icons.Event.video
            } else {
                Icons.Event.link
            }
            return isInProgress ? icon.with(color: .controlAccentColor) : icon

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
            return Strings.Event.Action.open
        case .link(let link, _):
            return link.isMeeting ? Strings.Event.Action.join : link.url.host() ?? "???"
        case .skip:
            return Strings.Event.Action.skip
        case .status(.accept):
            return Strings.Event.Action.accept
        case .status(.maybe):
            return Strings.Event.Action.maybe
        case .status(.decline):
            return Strings.Event.Action.decline
        }
    }
}
