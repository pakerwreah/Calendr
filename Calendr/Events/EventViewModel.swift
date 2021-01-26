//
//  EventViewModel.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import RxCocoa
import RxSwift

class EventViewModel {

    let title: String
    let duration: String
    let color: CGColor

    let isFaded: Observable<Bool>
    let progress: Observable<CGFloat?>

    init(
        event: EventModel,
        dateProvider: DateProviding = DateProvider(),
        scheduler: SchedulerType = MainScheduler.instance
    ) {

        title = event.title
        color = event.calendar.color

        // fix range ending at 00:00 of the next day
        let fixedEnd = dateProvider.calendar.date(byAdding: .second, value: -1, to: event.end)!
        let isSingleDay = dateProvider.calendar.isDate(event.start, inSameDayAs: fixedEnd)

        let formatter = DateFormatter(template: isSingleDay ? "Hm" : "ddMMyyyyHm")
        let start = formatter.string(from: event.start)
        let end = formatter.string(from: event.end)

        if event.isAllDay {
            duration = ""
        } else if isSingleDay {
            duration = "\(start) - \(end)"
        } else {
            duration = "Start: \(start)\nEnd:   \(end)"
        }

        let total = dateProvider.calendar
            .dateComponents([.second], from: event.start, to: event.end)
            .second ?? 0

        let clock = Observable<Int>.interval(.seconds(1), scheduler: scheduler)
            .toVoid()
            .startWith(())
            .share(replay: 1)

        progress = total <= 0 || !isSingleDay || event.isAllDay ? .just(nil) : clock.map {
            guard
                dateProvider.calendar.isDate(event.end, greaterThanOrEqualTo: dateProvider.now, granularity: .second),
                let ellapsed = dateProvider.calendar.dateComponents(
                    [.second], from: event.start, to: dateProvider.now
                ).second, ellapsed >= 0
            else { return nil }

            return CGFloat(ellapsed) / CGFloat(total)
        }
        .distinctUntilChanged()
        .share(replay: 1)

        isFaded = clock.map {
            return dateProvider.calendar.isDate(event.start, inSameDayAs: dateProvider.now)
                && dateProvider.calendar.isDate(event.end, lessThan: dateProvider.now, granularity: .second)
        }
        .distinctUntilChanged()
        .share(replay: 1)
    }
}
