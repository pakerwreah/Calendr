//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Foundation
import RxSwift

enum EventDetailsSource {
    case list
    case menubar
}

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
    let popoverSettings: PopoverSettings
    let showSkip: Bool

    let isInProgress: Observable<Bool>
    let close: Observable<Void>

    let linkTapped: AnyObserver<Void>
    let skipTapped: AnyObserver<Void>
    let isShowingObserver: AnyObserver<Bool>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let callback: AnyObserver<ContextCallbackAction>
    private let action = PublishSubject<ContextCallbackAction>()

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
        isInProgress: Observable<Bool>,
        source: EventDetailsSource,
        callback: AnyObserver<ContextCallbackAction>
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.popoverSettings = popoverSettings
        self.isShowingObserver = isShowingObserver
        self.isInProgress = isInProgress
        self.workspace = workspace

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

        link = event.detectLink(using: workspace)

        linkTapped = .init { [link] _ in
            if let link {
                workspace.open(link.url)
            }
        }

        showSkip = !type.isReminder && source ~= .menubar

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

        let closeSubject = PublishSubject<Void>()

        close = closeSubject.asObservable()

        self.callback = callback.mapObserver {
            closeSubject.onNext(())
            return $0
        }

        skipTapped = self.callback.mapObserver { _ in
            return .event(.skip)
        }
    }

    func makeContextMenuViewModel() -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: .details,
            callback: callback.asObserver()
        )
    }
}
