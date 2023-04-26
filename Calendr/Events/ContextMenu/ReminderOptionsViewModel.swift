//
//  ReminderOptionsViewModel.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

enum ReminderAction: Equatable {
    case open
    case complete(_ color: NSColor)
    case remind(DateComponents)
}

class ReminderOptionsViewModel: ContextMenuViewModel {
    typealias Action = ReminderAction

    private let actionCallbackObserver: AnyObserver<Void>
    let actionCallback: Observable<Void>

    private(set) var items: [ActionItem] = []

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let disposeBag = DisposeBag()

    init(
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
            items.append(contentsOf: [.action(.open), .separator])
        }

        items.append(contentsOf: [
            .action(.complete(event.calendar.color)),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ])
    }

    private func triggerAction( _ action: Action) -> Observable<Void> {

        switch action {
        case .open:
            workspace.open(URL(string: "x-apple-reminderkit://remcdreminder/\(event.id)")!)
            return .just(())

        case .complete:
            return calendarService.completeReminder(id: event.id)

        case .remind(let dateComponents):
            let date = dateProvider.calendar.date(byAdding: dateComponents, to: dateProvider.now)!
            return calendarService.rescheduleReminder(id: event.id, to: date)
        }
    }

    func triggerAction(_ action: Action) {

        triggerAction(action)
            .subscribe(
                onNext: actionCallbackObserver.onNext,
                onError: actionCallbackObserver.onError
            )
            .disposed(by: disposeBag)
    }
}

private enum Constants {

    static let formatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter
    }()
}

extension ReminderAction: ContextMenuAction {

    var icon: NSImage? {
        switch self {
        case .open:
            return Icons.Reminder.open
        case .complete(let color):
            return Icons.Reminder.complete.with(color: color)
        case .remind:
            return nil
        }
    }

    var title: String {
        switch self {
        case .open:
            return Strings.EventAction.open
        case .complete:
            return Strings.Reminder.Options.complete
        case .remind(let dateComponents):
            return Strings.Reminder.Options.remind(Constants.formatter.localizedString(from: dateComponents))
        }
    }
}
