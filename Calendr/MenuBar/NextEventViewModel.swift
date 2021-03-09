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
        settings: NextEventSettings,
        eventsObservable: Observable<[EventModel]>,
        dateProvider: DateProviding,
        scheduler: SchedulerType = MainScheduler.instance
    ) {

        typealias NextEventTuple = (event: EventModel, isInProgress: Bool)

        let nextEventObservable = Observable.combineLatest(settings.showEventStatusItem, eventsObservable)
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
                                    dateProvider.now, greaterThanOrEqualTo: event.start, granularity: .second
                                )
                                return (event, isInProgress)
                            }
                    }
            }
            .share()

        barColor = nextEventObservable
            .skipNil()
            .map(\.event.calendar.color)
            .distinctUntilChanged()

        backgroundColor = nextEventObservable
            .skipNil()
            .map { $0.isInProgress ? $0.event.calendar.color.copy(alpha: 0.2)!: .clear }
            .distinctUntilChanged()
        
        title = nextEventObservable
            .skipNil()
            .map(\.event.title)
            .distinctUntilChanged()

        let dateFormatter = DateComponentsFormatter()
        dateFormatter.calendar = dateProvider.calendar
        dateFormatter.unitsStyle = .abbreviated
        dateFormatter.maximumUnitCount = 2

        time = nextEventObservable
            .skipNil()
            .map { [dateProvider] event, isInProgress in

                dateFormatter.allowedUnits = [.hour, .minute]

                var date = (isInProgress ? event.end : event.start)

                let diff = dateProvider.calendar.dateComponents([.minute, .second], from: dateProvider.now, to: date)

                if diff.minute == 0, diff.second! <= 30 {
                    dateFormatter.allowedUnits = [.second]
                }
                else if diff.second! > 0 {
                    dateProvider.calendar.date(byAdding: .minute, value: 1, to: date).map { date = $0 }
                }

                var time = dateFormatter.string(from: dateProvider.now, to: date) ?? ""

                if !isInProgress {
                    time = "\(Strings.Formatter.Date.Relative.in) \(time)"
                }

                return time
            }
            .distinctUntilChanged()

        hasEvent = nextEventObservable
            .map(\.isNotNil)
            .distinctUntilChanged()
    }
}
