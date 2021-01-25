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

    let progress: Observable<CGFloat?>

    init(
        event: EventModel,
        dateProvider: DateProviding = DateProvider(),
        scheduler: SchedulerType = MainScheduler.instance
    ) {

        title = event.title
        color = event.calendar.color

        let isSingleDay = dateProvider.calendar.isDate(event.start, inSameDayAs: event.end)

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

        let clock = Observable<Int>.interval(.seconds(1), scheduler: scheduler).toVoid()

        progress = total <= 0 ? .just(nil) : clock.compactMap {

            guard
                let ellapsed = dateProvider.calendar.dateComponents(
                    [.second], from: event.start, to: dateProvider.now
                ).second, ellapsed >= 0
            else { return nil }

            return CGFloat(ellapsed) / CGFloat(total)
        }
    }
}
