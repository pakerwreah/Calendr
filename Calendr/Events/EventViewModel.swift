//
//  EventViewModel.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift

class EventViewModel {

    let identifier: String
    let title: String
    let subtitle: String
    let duration: String
    let color: NSColor
    let isPending: Bool
    let isBirthday: Bool
    let isMeeting: Bool
    let linkURL: URL?

    let isInProgress: Observable<Bool>
    let backgroundColor: Observable<NSColor>
    let isFaded: Observable<Bool>
    let progress: Observable<CGFloat?>

    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let settings: EventSettings

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        settings: EventSettings,
        scheduler: SchedulerType = WallTimeScheduler()
    ) {

        self.settings = settings
        self.dateProvider = dateProvider
        self.calendarService = calendarService

        identifier = event.id
        title = event.title
        color = event.calendar.color
        isPending = event.isPending
        isBirthday = event.isBirthday

        let links = !event.isAllDay
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

        if let location = event.location {
            subtitle = location
        } else {
            subtitle = linkURL?.absoluteString ?? ""
        }

        // fix range ending at 00:00 of the next day
        let fixedEnd = dateProvider.calendar.date(byAdding: .second, value: -1, to: event.end)!
        let endsToday = dateProvider.calendar.isDate(fixedEnd, inSameDayAs: dateProvider.now)
        let isSingleDay = dateProvider.calendar.isDate(event.start, inSameDayAs: fixedEnd)
        let isSameMonth = dateProvider.calendar.isDate(event.start, equalTo: fixedEnd, toGranularity: .month)
        let startsMidnight = dateProvider.calendar.date(event.start, matchesComponents: .init(hour: 0, minute: 0))
        let endsMidnight = dateProvider.calendar.date(event.end, matchesComponents: .init(hour: 0, minute: 0))
        let showTime = !(startsMidnight && endsMidnight)

        if event.isAllDay {

            duration = ""

        } else if isSingleDay {

            let formatter = DateIntervalFormatter()
            formatter.dateTemplate = "jm"
            formatter.locale = dateProvider.calendar.locale!

            let end = endsMidnight ? dateProvider.calendar.startOfDay(for: event.start) : event.end

            duration = formatter.string(from: event.start, to: end)

        } else if !showTime {

            let formatter = DateIntervalFormatter()
            formatter.dateTemplate = isSameMonth ? "ddMMMM" : "ddMMM"
            formatter.locale = dateProvider.calendar.locale!

            duration = formatter.string(from: event.start, to: fixedEnd)

        } else {

            let formatter = DateFormatter(
                template: "ddMMyyyyHm",
                locale: dateProvider.calendar.locale!
            )
            let start = formatter.string(from: event.start)
            let end = formatter.string(from: showTime ? event.end : fixedEnd)

            duration = "\(start)\n\(end)"
        }

        let total = event.start.distance(to: event.end)
        let secondsToStart = Int(dateProvider.now.distance(to: event.start))
        let secondsToEnd = Int(dateProvider.now.distance(to: event.end).rounded(.up)) + 1

        let isPast: Observable<Bool>
        let clock: Observable<Void>

        if secondsToEnd > 0 {

            isPast = Observable<Int>.timer(.seconds(secondsToEnd), scheduler: scheduler)
                .toVoid()
                .map { true }
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

        progress = total <= 0 || event.isAllDay || !isSingleDay || !endsToday
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

        isFaded = event.isAllDay || !endsToday ? .just(false) : isPast

        isInProgress = progress.map(\.isNotNil).distinctUntilChanged()

        let progressBackgroundColor = color.withAlphaComponent(0.15)

        backgroundColor = isInProgress.map { $0 ? progressBackgroundColor : .clear }
    }

    func makeDetails() -> EventDetailsViewModel? {
        EventDetailsViewModel(
            identifier: identifier,
            dateProvider: dateProvider,
            calendarService: calendarService,
            settings: settings
        )
    }
}
