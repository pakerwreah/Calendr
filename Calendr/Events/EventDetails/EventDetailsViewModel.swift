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
    let isShowingObserver: AnyObserver<Bool>

    let popoverSettings: PopoverSettings
    let workspace: WorkspaceServiceProviding

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding

    var accessibilityIdentifier: String? {
        switch type {
        case .event:
            return Accessibility.EventDetails.view
        case .reminder:
            return Accessibility.ReminderDetails.view
        case .birthday:
            return nil
        }
    }

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        popoverSettings: PopoverSettings,
        isShowingObserver: AnyObserver<Bool>,
        isInProgress: Observable<Bool>
    ) {

        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService

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
            duration = formatter.string(from: event.start, to: event.end)
        } else {
            formatter.timeStyle = .short

            let range = event.range(using: dateProvider)

            let end: Date

            if type.isReminder {
                end = event.start
            }
            else if range.isSingleDay && range.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            duration = EventUtils.duration(
                from: event.start,
                to: end,
                timeZone: event.timeZone,
                formatter: formatter,
                isMeeting: event.isMeeting
            )
        }
    }

    func makeContextMenuViewModel() -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: .details
        )
    }
}
