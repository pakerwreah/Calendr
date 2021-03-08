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
        workspace: WorkspaceServiceProviding,
        settings: EventSettings,
        scheduler: SchedulerType = WallTimeScheduler()
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
                workspace: workspace,
                scheduler: scheduler
            )
        }

        let refreshEvents = eventsObservable.flatMapLatest { events in
            Observable.merge(
                events
                    .filter(\.isAllDay.isFalse)
                    .compactMap {
                        dateProvider.calendar.dateComponents([.second], from: dateProvider.now, to: $0.end).second
                    }
                    .filter { $0 >= 0 }
                    .map {
                        Observable<Int>.timer(.seconds($0), scheduler: scheduler)
                    }
            )
            .toVoid()
            .startWith(())
            .map { events }
        }

        let visibleEvents = Observable.combineLatest(
            refreshEvents, settings.showPastEvents
        )
        .map { events, showPast in
            showPast ? events : events.filter {
                $0.isAllDay
                ||
                !dateProvider.calendar.isDate(
                    dateProvider.now, inSameDayAs: $0.start
                )
                ||
                dateProvider.calendar.isDate(
                    dateProvider.now, lessThan: $0.end, granularity: .second
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
                    .flatten()

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
