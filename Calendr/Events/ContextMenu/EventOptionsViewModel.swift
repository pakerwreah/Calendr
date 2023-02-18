//
//  EventOptionsViewModel.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

enum EventAction {
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
    private let calendarService: CalendarServiceProviding

    private let disposeBag = DisposeBag()

    init(
        event: EventModel,
        calendarService: CalendarServiceProviding
    ) {
        self.event = event
        self.calendarService = calendarService

        (actionCallback, actionCallbackObserver) = PublishSubject.pipe()

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

    func triggerAction(_ action: Action) {

        calendarService.changeEventStatus(id: event.id, date: event.start, to: action.status)
            .subscribe(
                onNext: actionCallbackObserver.onNext,
                onError: actionCallbackObserver.onError
            )
            .disposed(by: disposeBag)
    }
}

private extension EventAction {

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
        case .accept:
            return Strings.EventStatus.Action.accept
        case .maybe:
            return Strings.EventStatus.Action.maybe
        case .decline:
            return Strings.EventStatus.Action.decline
        }
    }
}
