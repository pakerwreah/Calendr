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
    let barStyle: EventBarStyle
    let type: EventType
    let isDeclined: Bool
    let link: EventLink?

    let isInProgress: Observable<Bool>
    let backgroundColor: Observable<NSColor>
    let isFaded: Observable<Bool>
    let progress: Observable<CGFloat?>

    private let isShowingDetails: AnyObserver<Bool>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let settings: PopoverSettings

    let workspace: WorkspaceServiceProviding

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        settings: PopoverSettings,
        isShowingDetails: AnyObserver<Bool>,
        scheduler: SchedulerType
    ) {

        self.event = event
        self.settings = settings
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace
        self.isShowingDetails = isShowingDetails

        title = event.title
        color = event.calendar.color
        type = event.type
        isDeclined = event.status ~= .declined
        barStyle = event.status ~= .maybe ? .bordered : .filled
        link = event.detectLink(using: workspace)

        subtitle = [event.location, link?.url.absoluteString, event.notes]
            .lazy
            .compactMap { $0?.replacingOccurrences(of: "https://", with: "").trimmed }
            .first(where: \.isEmpty.isFalse)?
            .prefix(while: \.isNewline.isFalse)
            .trimmed ?? ""

        let meta = event.meta(using: dateProvider)
        let showTime = !(meta.startsMidnight && meta.endsMidnight)

        if event.isAllDay {

            duration = ""

        } else if meta.isSingleDay {

            let formatter = DateIntervalFormatter()
            formatter.dateTemplate = "jm"
            formatter.calendar = dateProvider.calendar

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
            formatter.calendar = dateProvider.calendar

            duration = formatter.string(from: event.start, to: meta.fixedEnd)

        } else {

            let formatter = DateFormatter(template: "ddMMyyyyHm", calendar: dateProvider.calendar)
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
                .void()
                .concat(
                    Observable<Int>.interval(.seconds(1), scheduler: scheduler)
                        .void()
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

        if isDeclined {
            isFaded = .just(true)
        } else if event.isAllDay || !meta.endsToday {
            isFaded = .just(false)
        } else {
            isFaded = isPast
        }

        isInProgress = progress.map(\.isNotNil).distinctUntilChanged()

        let progressBackgroundColor = color.withAlphaComponent(0.15)

        backgroundColor = isInProgress.map { $0 ? progressBackgroundColor : .clear }
    }

    func makeDetails() -> EventDetailsViewModel {
        .init(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            settings: settings,
            isShowingObserver: isShowingDetails,
            isInProgress: isInProgress
        )
    }
}
