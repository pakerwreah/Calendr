//
//  EventListViewModel.swift
//  Calendr
//
//  Created by Paker on 26/02/2021.
//

import RxCocoa
import RxSwift

enum EventListItem {
    case section(String)
    case interval(String, Observable<Bool>)
    case event(EventViewModel)
}

class EventListViewModel {

    private let viewModels: Observable<[EventListItem]>

    init(
        eventsObservable: Observable<[EventModel]>,
        dateProvider: DateProviding,
        workspaceProvider: WorkspaceProviding,
        settings: EventSettings,
        scheduler: SchedulerType = MainScheduler.instance
    ) {

        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.calendar = dateProvider.calendar
        dateComponentsFormatter.unitsStyle = .abbreviated
        dateComponentsFormatter.allowedUnits = [.hour, .minute]

        let dateFormatter = DateFormatter(
            locale: dateProvider.calendar.locale
        )
        .with(style: .short)

        func makeEventViewModel(_ event: EventModel) -> EventViewModel {
            EventViewModel(
                event: event,
                dateProvider: dateProvider,
                workspaceProvider: workspaceProvider,
                scheduler: scheduler
            )
        }

        let clock = Observable<Int>.interval(.seconds(1), scheduler: scheduler)
            .toVoid()
            .startWith(())

        let visibleEvents = Observable.combineLatest(
            eventsObservable, settings.showPastEvents, clock
        )
        .map { events, showPast, _ in
            showPast ? events : events.filter {
                $0.isAllDay
                ||
                !dateProvider.calendar.isDate(
                    dateProvider.now, inSameDayAs: $0.start
                )
                ||
                dateProvider.calendar.isDate(
                    dateProvider.now, lessThanOrEqualTo: $0.end, granularity: .second
                )
            }
        }
        .distinctUntilChanged()

        viewModels = visibleEvents
            .map { events in
                let allDayViewModels: [EventListItem] = events
                    .filter(\.isAllDay)
                    .sorted {
                        $0.calendar.color.hashValue < $1.calendar.color.hashValue
                    }
                    .map {
                        .event(makeEventViewModel($0))
                    }

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

                            let today = dateProvider.calendar.isDate(curr.start, inSameDayAs: dateProvider.now)
                                ? Strings.Formatter.Date.today
                                : dateFormatter.string(from: curr.start)

                            return [.section(today), eventItem]
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
                    .flatMap { $0 }

                guard allDayViewModels.isEmpty else {
                    return [.section(Strings.Formatter.Date.allDay)] + allDayViewModels + viewModels
                }

                return viewModels
            }
            .share(replay: 1)
    }

    func asObservable() -> Observable<[EventListItem]> {
        return viewModels
    }
}

private extension Sequence {

    func prevMap<T>(_ transform: ((prev: Element?, curr: Element)) throws -> T) rethrows -> [T] {
        var prev: Element? = nil
        return try map { curr -> T in
            defer { prev = curr }
            return try transform((prev, curr))
        }
    }
}
