//
//  EventOptionsViewModel.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

enum EventAction {
    case open
    case accept
    case maybe
    case decline
}

class EventOptionsViewModel: ContextMenuViewModel {
    typealias Action = EventAction

    private let actionCallbackObserver: AnyObserver<Void>
    let actionCallback: Observable<Void>

    private(set) var items: [ActionItem] = []

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let disposeBag = DisposeBag()

    init?(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        source: ContextMenuSource
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace

        (actionCallback, actionCallbackObserver) = PublishSubject.pipe()

        if source ~= .list {
            items.append(.action(.open))
        }

        if event.status != .unknown {
            if !items.isEmpty {
                items.append(.separator)
            }
            if event.status != .accepted {
                items.append(.action(.accept))
            }
            if event.status != .maybe {
                items.append(.action(.maybe))
            }
            if event.status != .declined {
                items.append(.action(.decline))
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

    func triggerAction(_ action: Action) {

        if action ~= .open {
            return openEvent()
        }

        guard let newStatus = action.status else { return }

        calendarService.changeEventStatus(id: event.id, date: event.start, to: newStatus)
            .subscribe(
                onNext: actionCallbackObserver.onNext,
                onError: actionCallbackObserver.onError
            )
            .disposed(by: disposeBag)
    }
}

private extension EventAction {

    var status: EventStatus? {
        switch self {
        case .accept:
            return .accepted
        case .maybe:
            return .maybe
        case .decline:
            return .declined
        default:
            return nil
        }
    }
}

extension EventAction: ContextMenuAction {

    var icon: NSImage? {
        switch self {
        case .open:
            return Icons.Event.open
        case .accept:
            return Icons.EventStatus.accepted.with(color: .systemGreen)
        case .maybe:
            return Icons.EventStatus.maybe.with(color: .systemOrange)
        case .decline:
            return Icons.EventStatus.declined.with(color: .systemRed)
        }
    }

    var title: String {
        switch self {
        case .open:
            return Strings.EventAction.open
        case .accept:
            return Strings.EventAction.accept
        case .maybe:
            return Strings.EventAction.maybe
        case .decline:
            return Strings.EventAction.decline
        }
    }
}
