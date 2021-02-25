//
//  NextEventViewModel.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import RxCocoa
import RxSwift

class NextEventViewModel {

    let title: Observable<String>
    let time: Observable<String>
    let barColor: Observable<CGColor>
    let backgroundColor: Observable<CGColor>
    let hasEvent: Observable<Bool>

    init(
        isEnabled: Observable<Bool>,
        eventsObservable: Observable<[EventModel]>,
        dateProvider: DateProviding,
        scheduler: SchedulerType = MainScheduler.instance
    ) {

        typealias NextEventTuple = (event: EventModel, isInProgress: Bool)

        let nextEventObservable = Observable.combineLatest(isEnabled, eventsObservable)
            .map { isEnabled, events in
                isEnabled ? events.filter { !$0.isAllDay && !$0.isPending } : []
            }
            .flatMapLatest { [dateProvider] events -> Observable<NextEventTuple?> in

                Observable<Int>.interval(.seconds(1), scheduler: scheduler)
                    .toVoid()
                    .startWith(())
                    .map {
                        events
                            .first(where: { event in
                                dateProvider.calendar.isDate(
                                    dateProvider.now, lessThan: event.end, granularity: .second
                                )
                            })
                            .map { event -> NextEventTuple in
                                let isInProgress = dateProvider.calendar.isDate(
                                    dateProvider.now, greaterThan: event.start, granularity: .second
                                )
                                return (event, isInProgress)
                            }
                    }
            }

        barColor = nextEventObservable
            .compactMap { $0 }
            .map(\.event.calendar.color)
            .distinctUntilChanged()

        backgroundColor = nextEventObservable
            .compactMap { $0 }
            .map { $0.isInProgress ? $0.event.calendar.color.copy(alpha: 0.2)!: .clear }
            .distinctUntilChanged()
        
        title = nextEventObservable
            .compactMap { $0 }
            .map { "\($0.event.title) " }
            .distinctUntilChanged()

        let startDateFormatter = RelativeDateTimeFormatter()
        startDateFormatter.calendar = dateProvider.calendar
        startDateFormatter.unitsStyle = .abbreviated

        let endDateFormatter = DateComponentsFormatter()
        endDateFormatter.calendar = dateProvider.calendar
        endDateFormatter.unitsStyle = .abbreviated
        endDateFormatter.maximumUnitCount = 2

        time = nextEventObservable
            .compactMap { $0 }
            .map { [dateProvider] event, isInProgress in
                if !isInProgress {
                    return startDateFormatter.localizedString(for: event.start, relativeTo: dateProvider.now)
                }
                else {
                    endDateFormatter.allowedUnits =
                        dateProvider.now.distance(to: event.end) < 60
                        ? [.second]
                        : [.hour, .minute]
                    return endDateFormatter.string(from: dateProvider.now, to: event.end) ?? ""
                }
            }
            .distinctUntilChanged()

        hasEvent = nextEventObservable
            .map(\.isNotNil)
            .distinctUntilChanged()
    }
}
