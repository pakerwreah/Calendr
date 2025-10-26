//
//  EventListViewModel.swift
//  Calendr
//
//  Created by Paker on 26/02/2021.
//

import Cocoa
import RxSwift

enum EventListItem {
    case section(String)
    case interval(EventIntervalViewModel)
    case event(EventViewModel)
}

private extension EventListItem {
    var event: EventViewModel? { if case .event(let event) = self { event } else { nil } }
}

struct EventListSummaryItem: Equatable {
    let colors: Set<NSColor>
    let count: Int
}

struct EventListSummary: Equatable {
    let overdue: EventListSummaryItem
    let allday: EventListSummaryItem
    let today: EventListSummaryItem
}

class EventListViewModel {

    private let disposeBag = DisposeBag()

    private let isShowingDetailsModal: BehaviorSubject<Bool>
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let geocoder: GeocodeServiceProviding
    private let weatherService: WeatherServiceProviding
    private let workspace: WorkspaceServiceProviding
    private let userDefaults: UserDefaults
    private let settings: EventListSettings
    private let scheduler: SchedulerType
    private let refreshScheduler: SchedulerType
    private let eventsScheduler: SchedulerType

    private let dateFormatter: DateFormatter
    private let relativeFormatter: RelativeDateTimeFormatter
    private let dateComponentsFormatter: DateComponentsFormatter

    private struct EventListProps: Equatable {
        var events: [EventModel]
        let date: Date
        let showPastEvents: Bool
        let showOverdueReminders: Bool
        let isTodaySelected: Bool
    }

    private struct EventListGroups {
        let overdue: [EventListItem]
        let allday: [EventListItem]
        let today: [EventListItem]
    }

    private let groups = BehaviorSubject<EventListGroups>(value: .init(overdue: [], allday: [], today: []))

    let items: Observable<[EventListItem]>
    let summary: Observable<EventListSummary>

    init(
        eventsObservable: Observable<(Date, [EventModel])>,
        isShowingDetailsModal: BehaviorSubject<Bool>,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        userDefaults: UserDefaults,
        settings: EventListSettings,
        scheduler: SchedulerType,
        refreshScheduler: SchedulerType,
        eventsScheduler: SchedulerType
    ) {
        self.isShowingDetailsModal = isShowingDetailsModal
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.geocoder = geocoder
        self.weatherService = weatherService
        self.workspace = workspace
        self.userDefaults = userDefaults
        self.settings = settings
        self.scheduler = scheduler
        self.refreshScheduler = refreshScheduler
        self.eventsScheduler = eventsScheduler

        dateFormatter = DateFormatter(calendar: dateProvider.calendar)
        dateFormatter.dateStyle = .short

        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named

        dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.calendar = dateProvider.calendar
        dateComponentsFormatter.unitsStyle = .abbreviated
        dateComponentsFormatter.allowedUnits = [.hour, .minute]

        items = groups.map {
            $0.overdue + $0.allday + $0.today
        }.share(replay: 1)

        summary = groups.flatMapLatest { groups in

            let overduePast = Observable.just(groups.overdue.compactMap(\.event))

            let overdueToday: Observable<[EventViewModel]> = Observable.combineLatest(
                groups.today
                    .compactMap(\.event)
                    .filter(\.type.isReminder)
                    .map { event -> Observable<EventViewModel?> in
                        event.isInProgress.map { $0 ? event : nil }
                    }
            ).map { $0.compact() }

            let allday = Observable.just(groups.allday.compactMap(\.event))

            // pending events except overdue today
            let today: Observable<[EventViewModel]> = Observable.combineLatest(
                groups.today.compactMap(\.event).map { event -> Observable<EventViewModel?> in
                    Observable
                        .combineLatest(event.isFaded, event.isInProgress)
                        .map { isFaded, isInProgress -> EventViewModel? in
                            isFaded || (event.type.isReminder && isInProgress) ? nil : event
                        }
                }
            ).map { $0.compact() }

            func makeItem(_ items: [EventViewModel]) -> EventListSummaryItem {
                let r = Dictionary(grouping: items, by: \.color)
                return .init(colors: Set(r.keys) , count: r.values.map(\.count).reduce(0, +))
            }

            return Observable.combineLatest(overduePast, overdueToday, allday, today)
                .map { overduePast, overdueToday, allday, today in
                    EventListSummary(
                        overdue: makeItem(overduePast + overdueToday),
                        allday: makeItem(allday),
                        today: makeItem(today)
                    )
                }
        }
        .share(replay: 1)

        Observable.combineLatest(
            eventsObservable,
            settings.showPastEvents,
            settings.showOverdueReminders,
            isShowingDetailsModal
        )
        .compactMap { dateEvents, showPast, showOverdue, isShowingDetailsModal -> EventListProps? in
            guard !isShowingDetailsModal else { return nil }
            let (date, events) = dateEvents
            let isTodaySelected = dateProvider.calendar.isDate(date, inSameDayAs: dateProvider.now)

            return .init(
                events: events,
                date: date,
                showPastEvents: showPast,
                showOverdueReminders: showOverdue,
                isTodaySelected: isTodaySelected
            )
        }
        .distinctUntilChanged()
        .flatMapLatest { props -> Observable<EventListProps> in

            guard props.isTodaySelected && !props.showPastEvents else {
                return .just(props)
            }

            // schedule refresh for every event end to hide past events
            return Observable.merge(
                props.events
                    .filter {
                        !$0.isAllDay && !$0.type.isReminder && $0.range(using: dateProvider).endsToday
                    }
                    .map {
                        Int(dateProvider.now.distance(to: $0.end).rounded(.up)) + 1
                    }
                    .filter { $0 >= 0 }
                    .map {
                        Observable<Int>.timer(.seconds($0), scheduler: refreshScheduler)
                    }
            )
            .void()
            .startWith(())
            .map {
                var props = props
                props.events = props.events.filter {
                    if case .reminder(let completed) = $0.type {
                        return !completed
                    }
                    return $0.isAllDay || !$0.range(using: dateProvider).isPast
                }
                return props
            }
        }
        // build event list
        .compactMap { [weak self] props -> EventListGroups? in
            guard let self else { return nil }

            let overdue = overdueViewModels(props)
            let allday = allDayViewModels(props)
            let today = todayViewModels(props)

            return EventListGroups(overdue: overdue, allday: allday, today: today)
        }
        .bind(to: groups)
        .disposed(by: disposeBag)
    }

    // MARK: - Private

    private func makeEventViewModel(_ event: EventModel, _ isTodaySelected: Bool) -> EventViewModel {
        EventViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: userDefaults,
            settings: settings,
            isShowingDetailsModal: isShowingDetailsModal.asObserver(),
            isTodaySelected: isTodaySelected,
            scheduler: eventsScheduler
        )
    }

    private func isOverdue(_ event: EventModel) -> Bool {
        event.type.isReminder
        && dateProvider.calendar.isDate(event.start, lessThan: dateProvider.now, granularity: .day)
    }

    private func overdueViewModels(_ props: EventListProps) -> [EventListItem] {

        guard props.showOverdueReminders else { return [] }

        return props.events
            .filter { isOverdue($0) && props.isTodaySelected }
            .sorted(by: \.start)
            .prevMap { prev, curr -> [EventListItem] in

                let viewModel = makeEventViewModel(curr, props.isTodaySelected)
                let eventItem: EventListItem = .event(viewModel)

                guard let prev, dateProvider.calendar.isDate(curr.start, inSameDayAs: prev.start) else {
                    let label = props.isTodaySelected
                        ? relativeFormatter.localizedString(for: curr.start, relativeTo: dateProvider.now).ucfirst
                        : dateFormatter.string(from: curr.start)
                    return [.section(label), eventItem]
                }

                return [eventItem]
            }
            .flatten()
    }

    private func allDayViewModels(_ props: EventListProps) -> [EventListItem] {
        var viewModels: [EventListItem] = props.events
            .filter { $0.isAllDay && (!isOverdue($0) || !props.isTodaySelected) }
            .sorted(by: \.calendar.color.hashValue)
            .map { .event(makeEventViewModel($0, props.isTodaySelected)) }

        if !viewModels.isEmpty {
            viewModels.insert(.section(Strings.Event.allDay), at: 0)
        }
        return viewModels
    }

    private func todayViewModels(_ props: EventListProps) -> [EventListItem] {
        props.events
            .filter { !$0.isAllDay && (!isOverdue($0) || !props.isTodaySelected) }
            .sorted {
                ($0.start, $0.end) < ($1.start, $1.end)
            }
            .prevMap { prev, curr -> [EventListItem] in

                let viewModel = makeEventViewModel(curr, props.isTodaySelected)
                let eventItem: EventListItem = .event(viewModel)

                guard let prev else {
                    // if first event, show today section
                    let title = props.isTodaySelected
                        ? Strings.Formatter.Date.today
                        : dateFormatter.string(from: props.date)

                    return [.section(title), eventItem]
                }

                guard prev.end.distance(to: curr.start) >= 60 else {
                    return [eventItem]
                }

                let fade = Observable
                    .merge(viewModel.isFaded, viewModel.isInProgress)
                    .take(until: \.isTrue, behavior: .inclusive)

                let ticker = Observable<Int>.interval(.seconds(1), scheduler: scheduler).void().startWith(())

                let interval = ticker.compactMap { [dateProvider, dateComponentsFormatter] in

                    let isUpcoming = dateProvider.calendar.isDate(
                        dateProvider.now, in: (prev.end, curr.start),
                        granularity: .second
                    )

                    let truncatedNow = Date(timeIntervalSince1970: floor(dateProvider.now.timeIntervalSince1970 / 60) * 60)

                    return dateComponentsFormatter.string(
                        from: isUpcoming ? truncatedNow : prev.end,
                        to: curr.start
                    )
                }

                let intervalViewModel = EventIntervalViewModel(text: interval, fade: fade)

                return [.interval(intervalViewModel), eventItem]
            }
            .flatten()
    }
}
