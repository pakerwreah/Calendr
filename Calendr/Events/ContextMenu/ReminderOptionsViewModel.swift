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

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        source: ContextMenuSource,
        callback: AnyObserver<ReminderAction>
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace

        super.init(callback: callback)

        if [.list, .menubar].contains(source) {
            addItem(.open)
        }

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
            workspace.open(URL(string: "x-apple-reminderkit://remcdreminder/\(event.id)")!)
            return .empty()

        case .complete:
            return calendarService.completeReminder(id: event.id)

        case .remind(let dateComponents):
            let date = dateProvider.calendar.date(byAdding: dateComponents, to: dateProvider.now)!
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
            return Strings.EventAction.open
        case .complete:
            return Strings.Reminder.Options.complete
        case .remind(let dateComponents):
            return Strings.Reminder.Options.remind(Constants.formatter.localizedString(from: dateComponents))
        }
    }
}
