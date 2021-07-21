//
//  EventViewModel.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift

class EventViewModel {

    let title: String
    let subtitle: String
    let duration: String
    let color: NSColor
    let isPending: Bool
    let type: EventType
    let isMeeting: Bool
    let linkURL: URL?

    let isInProgress: Observable<Bool>
    let backgroundColor: Observable<NSColor>
    let isFaded: Observable<Bool>
    let progress: Observable<CGFloat?>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let settings: EventSettings

    let workspace: WorkspaceServiceProviding

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        settings: EventSettings,
        scheduler: SchedulerType = WallTimeScheduler()
    ) {

        self.event = event
        self.settings = settings
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace

        title = event.title
        color = event.calendar.color
        isPending = event.isPending
        type = event.type

        let links = !event.type.isBirthday
            ? workspace.detectLinks([event.location, event.url?.absoluteString, event.notes])
            : []

        if let meetingURL = links.compactMap(workspace.detectMeeting).first {
            isMeeting = true
            linkURL = meetingURL
        }
        else {
            isMeeting = false
            linkURL = links.first
        }

        let url = linkURL?.absoluteString

        subtitle = (event.location ?? url ?? event.notes)?
            .replacingOccurrences(of: "https://", with: "")
            .prefix(while: \.isNewline.isFalse)
            .trimmed ?? ""

        let meta = event.meta(using: dateProvider)
        let showTime = !(meta.startsMidnight && meta.endsMidnight)

        if event.isAllDay {

            duration = ""

        } else if meta.isSingleDay {

            let formatter = DateIntervalFormatter()
            formatter.dateTemplate = "jm"
            formatter.locale = dateProvider.calendar.locale!

            let end: Date

            if event.type.isReminder {
                end = event.start
            }
            else if meta.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            duration = formatter.string(from: event.start, to: end)

        } else if !showTime {

            let formatter = DateIntervalFormatter()
            formatter.dateTemplate = meta.isSameMonth ? "ddMMMM" : "ddMMM"
            formatter.locale = dateProvider.calendar.locale!

            duration = formatter.string(from: event.start, to: meta.fixedEnd)

        } else {

            let formatter = DateFormatter(
                template: "ddMMyyyyHm",
                locale: dateProvider.calendar.locale!
            )
            let start = formatter.string(from: event.start)
            let end = formatter.string(from: showTime ? event.end : meta.fixedEnd)

            duration = "\(start)\n\(end)"
        }

        let total = event.start.distance(to: event.end)
        let secondsToStart = Int(dateProvider.now.distance(to: event.start))
        let secondsToEnd = Int(dateProvider.now.distance(to: event.end).rounded(.up)) + 1

        let isPast: Observable<Bool>
        let clock: Observable<Void>

        if secondsToEnd > 0 {

            isPast = Observable<Int>.timer(.seconds(secondsToEnd), scheduler: scheduler)
                .map(true)
                .startWith(false)
                .share(replay: 1)

            clock = Observable<Int>.timer(.seconds(secondsToStart), scheduler: scheduler)
                .toVoid()
                .concat(
                    Observable<Int>.interval(.seconds(1), scheduler: scheduler)
                        .toVoid()
                        .startWith(())
                )
                .startWith(())
                .take(until: isPast.matching(true))

        } else {
            isPast = .just(true)
            clock = .empty()
        }

        progress = total <= 0 || event.isAllDay || !meta.isSingleDay || !meta.endsToday
            ? .just(nil)
            : clock.map {

                let ellapsed = event.start.distance(to: dateProvider.now)

                guard
                    ellapsed >= 0,
                    dateProvider.calendar.isDate(
                        dateProvider.now, lessThanOrEqualTo: event.end, granularity: .second
                    )
                else { return nil }

                return CGFloat(ellapsed / total)
            }
            .distinctUntilChanged()
            .concat(Observable.just(nil))
            .share(replay: 1)

        isFaded = event.isAllDay || !meta.endsToday ? .just(false) : isPast

        isInProgress = progress.map(\.isNotNil).distinctUntilChanged()

        let progressBackgroundColor = color.withAlphaComponent(0.15)

        backgroundColor = isInProgress.map { $0 ? progressBackgroundColor : .clear }
    }

    func makeDetails() -> EventDetailsViewModel {
        EventDetailsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            settings: settings
        )
    }
}
