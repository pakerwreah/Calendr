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

class ReminderOptionsViewModel: BaseContextMenuViewModel<ReminderAction> {

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
        callback: AnyObserver<ReminderAction>
    ) {
        guard
            case .reminder(let completed) = event.type,
            source == .list || !completed
        else { return nil }

        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace

        super.init(callback: callback)

        if [.list, .menubar].contains(source) {
            addItem(.open)
        }

        guard !completed else { return }

        addSeparator()
        addItem(.complete(event.calendar.color))
        
        addSeparator()
        addItems(
            .remind(.init(minute: 5)),
            .remind(.init(minute: 15)),
            .remind(.init(minute: 30)),
            .remind(.init(hour: 1)),
            .remind(.init(day: 1))
        )
    }

    override func onAction( _ action: Action) -> Completable {

        switch action {
        case .open:
            workspace.open(event)
            return .empty()

        case .complete:
            return calendarService.completeReminder(id: event.id, complete: true)

        case .remind(let dateComponents):
            guard
                let truncated = dateProvider.calendar.dateInterval(of: .minute, for: dateProvider.now)?.start,
                let date = dateProvider.calendar.date(byAdding: dateComponents, to: truncated)
            else {
                return .empty()
            }
            return calendarService.rescheduleReminder(id: event.id, to: date)
        }
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
            return Icons.Calendar.reminders
        case .complete(let color):
            return Icons.Reminder.complete.with(color: color)
        case .remind:
            return nil
        }
    }

    var title: String {
        switch self {
        case .open:
            return Strings.Event.Action.open
        case .complete:
            return Strings.Reminder.Options.complete
        case .remind(let dateComponents):
            return Strings.Reminder.Options.remind(Constants.formatter.localizedString(from: dateComponents))
        }
    }
}
