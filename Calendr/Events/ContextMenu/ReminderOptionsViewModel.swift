//
//  ReminderOptionsViewModel.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import Foundation
import RxSwift

enum ReminderAction: Equatable {
    case complete
    case remind(DateComponents)
}

class ReminderOptionsViewModel: ContextMenuViewModel {
    typealias Action = ReminderAction

    private let actionCallbackObserver: AnyObserver<Void>
    let actionCallback: Observable<Void>

    let items: [ActionItem]

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding

    private let disposeBag = DisposeBag()

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService

        (actionCallback, actionCallbackObserver) = PublishSubject.pipe()

        items = [
            .action(.complete),
            .separator,
            .action(.remind(.init(minute: 5))),
            .action(.remind(.init(minute: 15))),
            .action(.remind(.init(minute: 30))),
            .action(.remind(.init(hour: 1))),
            .action(.remind(.init(day: 1)))
        ]
    }

    private func triggerAction( _ action: Action) -> Observable<Void> {

        switch action {
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

    var title: String {
        switch self {
        case .complete:
            return Strings.Reminder.Options.complete
        case .remind(let dateComponents):
            return Strings.Reminder.Options.remind(Constants.formatter.localizedString(from: dateComponents))
        }
    }
}
