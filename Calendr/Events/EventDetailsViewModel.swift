//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Foundation
import RxSwift

class EventDetailsViewModel {

    let type: EventType
    let status: EventStatus
    let title: String
    let duration: String
    let url: String
    let location: String
    let notes: String
    let participants: [Participant]
    let link: EventLink?

    let isInProgress: Observable<Bool>
    let popoverSettings: PopoverSettings

    private let eventActionObservable: Observable<EventOptions.Action>
    let eventActionObserver: AnyObserver<EventOptions.Action>

    private let reminderActionObservable: Observable<ReminderOptions.Action>
    let reminderActionObserver: AnyObserver<ReminderOptions.Action>

    let actionCallback: Observable<Void>

    let isShowingObserver: AnyObserver<Bool>

    let workspace: WorkspaceServiceProviding

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        popoverSettings: PopoverSettings,
        isShowingObserver: AnyObserver<Bool>,
        isInProgress: Observable<Bool>
    ) {

        type = event.type
        status = event.status
        title = event.title
        url = (type.isBirthday ? nil : event.url?.absoluteString) ?? ""
        location = event.location ?? ""
        notes = event.notes ?? ""
        participants = event.participants.sorted {
            ($0.isOrganizer, $0.isCurrentUser, $0.status, $0.name)
            <
            ($1.isOrganizer, $1.isCurrentUser, $1.status, $1.name)
        }

        self.popoverSettings = popoverSettings
        self.isShowingObserver = isShowingObserver
        self.isInProgress = isInProgress
        self.workspace = workspace

        link = event.detectLink(using: workspace)

        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = dateProvider.calendar

        if event.isAllDay {
            formatter.timeStyle = .none
            duration = formatter.string(from: event.start, to: event.start)
        } else {
            formatter.timeStyle = .short

            let meta = EventMeta(event: event, dateProvider: dateProvider)

            let end: Date

            if type.isReminder {
                end = event.start
            }
            else if meta.isSingleDay && meta.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            duration = formatter.string(from: event.start, to: end)
        }

        (eventActionObservable, eventActionObserver) = PublishSubject.pipe()

        let eventActionCallback = !type.isEvent ? .empty() : eventActionObservable
            .flatMapFirst { action -> Observable<Void> in
                switch action {
                case .accept:
                    return calendarService.changeEventStatus(id: event.id, date: event.start, to: .accepted)
                case .maybe:
                    return calendarService.changeEventStatus(id: event.id, date: event.start, to: .maybe)
                case .decline:
                    return calendarService.changeEventStatus(id: event.id, date: event.start, to: .declined)
                }
            }

        (reminderActionObservable, reminderActionObserver) = PublishSubject.pipe()

        let reminderActionCallback = !type.isReminder ? .empty() : reminderActionObservable
            .flatMapFirst { action -> Observable<Void> in
                switch action {
                case .complete:
                    return calendarService.completeReminder(id: event.id)
                case .remind(let dateComponents):
                    let date = dateProvider.calendar.date(byAdding: dateComponents, to: dateProvider.now)!
                    return calendarService.rescheduleReminder(id: event.id, to: date)
                }
            }

        actionCallback = .merge(eventActionCallback, reminderActionCallback)
    }
}
