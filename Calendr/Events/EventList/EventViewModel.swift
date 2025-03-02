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
    let subtitleLink: String?
    let color: NSColor
    let barStyle: EventBarStyle
    let type: EventType
    let isDeclined: Bool
    let isAllDay: Bool
    let start: Date
    let link: EventLink?
    let priority: String?

    let duration: Observable<String>
    let isInProgress: Observable<Bool>
    let backgroundColor: Observable<EventBackground>
    let isFaded: Observable<Bool>
    let progress: Observable<CGFloat?>
    let isCompleted: Observable<Bool>
    let relativeDuration: Observable<String>
    let showRecurrenceIndicator: Observable<Bool>

    let linkTapped: AnyObserver<Void>

    private let completeTappedObservable: Observable<Void>
    let completeTapped: AnyObserver<Void>

    private let isShowingDetails: AnyObserver<Bool>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let geocoder: GeocodeServiceProviding
    private let weatherService: WeatherServiceProviding
    private let settings: EventSettings
    private let workspace: WorkspaceServiceProviding
    private let userDefaults: UserDefaults

    private let disposeBag = DisposeBag()

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        userDefaults: UserDefaults,
        settings: EventSettings,
        isShowingDetails: AnyObserver<Bool>,
        isTodaySelected: Bool,
        scheduler: SchedulerType
    ) {

        self.event = event
        self.settings = settings
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.workspace = workspace
        self.userDefaults = userDefaults
        self.geocoder = geocoder
        self.weatherService = weatherService
        self.isShowingDetails = isShowingDetails

        title = event.title
        color = event.calendar.color
        type = event.type
        isDeclined = event.status ~= .declined
        isAllDay = event.isAllDay
        start = event.start
        barStyle = event.status ~= .maybe ? .bordered : .filled
        link = event.detectLink(using: workspace)

        priority = switch event.priority {
            case .high: "!!!"
            case .medium: "!!"
            case .low: "!"
            default: nil
        }

        linkTapped = .init { [link] _ in
            if let link {
                workspace.open(link)
            }
        }

        (completeTappedObservable, completeTapped) = PublishSubject.pipe()

        if case .reminder(let wasCompleted) = type {

            self.isCompleted = completeTappedObservable
                .scan(wasCompleted) { isCompleted, _ in !isCompleted }
                .startWith(wasCompleted)
                .share(replay: 1, scope: .forever)

            isCompleted
                .debounce(.microseconds(600), scheduler: scheduler)
                .filter { $0 != wasCompleted }
                .flatMapFirst {
                    calendarService.completeReminder(id: event.id, complete: $0)
                }
                .subscribe()
                .disposed(by: disposeBag)
        } else {
            self.isCompleted = .just(false)
        }

        var subtitleText = event.location?.trimmed.replacingOccurrences(of: .newlines, with: " ") ?? ""
        let linkText = link?.url.domain
        let notes = event.notes?.trimmed ?? ""

        if let linkText, subtitleText.contains(linkText) {
            subtitleText = ""
        }

        if linkText == nil, subtitleText.isEmpty, !notes.hasPrefix(event.title) {
            subtitleText = notes
        }

        subtitle = subtitleText
        subtitleLink = linkText

        duration = settings.forceLocalTimeZone.map { forceLocalTimeZone in

            let timeZone = event.isMeeting || forceLocalTimeZone ? nil : event.timeZone
            let range = event.range(using: dateProvider, timeZone: timeZone)
            let showTime = !(range.startsMidnight && range.endsMidnight)

            if event.isAllDay && range.isSingleDay {

                return ""

            } else if range.isSingleDay || event.type.isReminder {

                let formatter = DateIntervalFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                formatter.calendar = dateProvider.calendar

                let end: Date

                if event.type.isReminder {
                    end = event.start
                }
                else if range.endsMidnight {
                    end = dateProvider.calendar.startOfDay(for: event.start)
                }
                else {
                    end = event.end
                }

                return EventUtils.duration(
                    from: event.start,
                    to: end,
                    timeZone: timeZone,
                    formatter: formatter
                )

            } else if showTime {

                let formatter = DateIntervalFormatter()
                formatter.dateTemplate = "ddMMyyyyHm"
                formatter.calendar = dateProvider.calendar

                return [
                    EventUtils.duration(
                        from: event.start,
                        to: event.start,
                        timeZone: timeZone,
                        formatter: formatter
                    ),
                    EventUtils.duration(
                        from: range.fixedEnd,
                        to: range.fixedEnd,
                        timeZone: timeZone,
                        formatter: formatter
                    )
                ].joined(separator: "\n")

            } else {

                let formatter = DateIntervalFormatter()
                formatter.dateTemplate = range.isSameMonth ? "ddMMMM" : "ddMMM"
                formatter.calendar = dateProvider.calendar

                return formatter.string(from: event.start, to: range.fixedEnd)
            }
        }

        let range = event.range(using: dateProvider)
        let total = event.start.distance(to: event.end)
        let secondsToStart = Int(dateProvider.now.distance(to: event.start))
        let secondsToEnd = Int(dateProvider.now.distance(to: event.end).rounded(.up)) + 1

        let isPast: Observable<Bool>
        let clock: Observable<Void>

        if isTodaySelected, !event.isAllDay, secondsToEnd > 0, event.type != .reminder(completed: true) {

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
            isPast = .just(secondsToEnd <= 0)
            clock = .just(())
        }

        if event.type == .reminder(completed: false), !event.isAllDay  {

            let dateFormatter = DateComponentsFormatter()
            dateFormatter.calendar = dateProvider.calendar
            dateFormatter.unitsStyle = .abbreviated
            dateFormatter.allowedUnits = [.day, .hour, .minute]
            dateFormatter.maximumUnitCount = 2
            dateFormatter.zeroFormattingBehavior = .dropAll

            relativeDuration = clock.compactMap {
                guard event.start.distance(to: dateProvider.now) > 60 else { return nil }

                return Strings.Formatter.Date.Relative.ago(
                    dateFormatter.string(from: event.start, to: dateProvider.now) ?? ""
                )
            }
            .distinctUntilChanged()
            .share(replay: 1)
        } else {
            relativeDuration = .empty()
        }

        progress = total <= 0 || event.isAllDay || !range.isSingleDay || !range.endsToday || event.type == .reminder(completed: true)
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
        } else if case .reminder(let completed) = type {
            isFaded = .just(isTodaySelected && completed)
        } else if event.isAllDay || !range.endsToday {
            isFaded = .just(false)
        } else {
            isFaded = isPast
        }

        isInProgress = progress.map(\.isNotNil).distinctUntilChanged()

        backgroundColor = isInProgress.map { isInProgress in
            guard event.status != .pending else { return .pending }
            return isInProgress ? .color(event.calendar.color.withAlphaComponent(0.15)) : .clear
        }

        showRecurrenceIndicator = settings.showRecurrenceIndicator.map { $0 && event.hasRecurrenceRules }
    }

    func makeDetailsViewModel() -> EventDetailsViewModel {

        EventDetailsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: userDefaults,
            settings: settings,
            isShowingObserver: isShowingDetails,
            isInProgress: isInProgress,
            source: .list,
            callback: .dummy()
        )
    }

    func makeContextMenuViewModel() -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: .list,
            callback: .dummy()
        )
    }
}
