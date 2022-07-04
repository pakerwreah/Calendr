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
    case interval(String, Observable<Bool>)
    case event(EventViewModel)
}

class EventListViewModel {

    private let disposeBag = DisposeBag()

    private let viewModels = BehaviorSubject<[EventListItem]>(value: [])
    private let isShowingDetails: BehaviorSubject<Bool>

    init(
        eventsObservable: Observable<(Date, [EventModel])>,
        isShowingDetails: BehaviorSubject<Bool>,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        settings: EventListSettings,
        scheduler: SchedulerType
    ) {

        self.isShowingDetails = isShowingDetails

        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.calendar = dateProvider.calendar
        dateComponentsFormatter.unitsStyle = .abbreviated
        dateComponentsFormatter.allowedUnits = [.hour, .minute]

        let dateFormatter = DateFormatter(calendar: dateProvider.calendar).with(style: .short)

        func makeEventViewModel(_ event: EventModel) -> EventViewModel {
            EventViewModel(
                event: event,
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings,
                isShowingDetails: isShowingDetails.asObserver(),
                scheduler: scheduler
            )
        }

        Observable.combineLatest(
            eventsObservable,
            settings.showPastEvents,
            isShowingDetails
        )
        .compactMap { dateEvents, showPast, isShowingDetails -> ([EventModel], Date, Bool)? in
            guard !isShowingDetails else { return nil }
            let (date, events) = dateEvents
            return (events, date, showPast)
        }
        .distinctUntilChanged(==)
        .flatMapLatest { events, date, showPast -> Observable<([EventModel], Date, Bool)> in

            let isToday = dateProvider.calendar.isDate(date, inSameDayAs: dateProvider.now)

            guard isToday && !showPast else { return .just((events, date, isToday)) }

            // schedule refresh for every event end to hide past events
            return Observable.merge(
                events
                    .filter {
                        !$0.isAllDay && $0.meta(using: dateProvider).endsToday
                    }
                    .map {
                        Int(dateProvider.now.distance(to: $0.end).rounded(.up)) + 1
                    }
                    .filter { $0 >= 0 }
                    .map {
                        Observable<Int>.timer(.seconds($0), scheduler: scheduler)
                    }
            )
            .void()
            .startWith(())
            .map {
                events.filter {
                    $0.isAllDay || !$0.meta(using: dateProvider).isPast
                }
            }
            .map { ($0, date, isToday) }
        }
        // build event list
        .map { events, date, isToday in

            let allDayViewModels: [EventListItem] = events
                .filter(\.isAllDay)
                .sorted(by: \.calendar.color.hashValue)
                .map { .event(makeEventViewModel($0)) }

            let viewModels = events
                .filter(\.isAllDay.isFalse)
                .sorted {
                    ($0.start, $0.end) < ($1.start, $1.end)
                }
                .prevMap { prev, curr -> [EventListItem] in

                    let viewModel = makeEventViewModel(curr)
                    let eventItem: EventListItem = .event(viewModel)

                    guard let prev = prev else {
                        // if first event, show today section
                        let title = isToday
                            ? Strings.Formatter.Date.today
                            : dateFormatter.string(from: date)

                        return [.section(title), eventItem]
                    }

                    // if not first, show interval between events
                    if dateProvider.calendar.isDate(
                        prev.end, lessThan: curr.start, granularity: .minute
                    ),
                    let diff = dateComponentsFormatter.string(
                        from: prev.end, to: curr.start
                    ) {
                        let fade = Observable.merge(
                            viewModel.isFaded,
                            viewModel.isInProgress
                        )
                        .take(until: \.isTrue, behavior: .inclusive)

                        return [.interval(diff, fade), eventItem]
                    }

                    return [eventItem]
                }
                .flatten()

            guard allDayViewModels.isEmpty else {
                return [.section(Strings.Formatter.Date.allDay)] + allDayViewModels + viewModels
            }

            return viewModels
        }
        .bind(to: viewModels)
        .disposed(by: disposeBag)
    }

    func asObservable() -> Observable<[EventListItem]> { viewModels }
}
