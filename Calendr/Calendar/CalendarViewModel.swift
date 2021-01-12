//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    init(dateObservable: Observable<Date>,
         hoverObservable: Observable<Date?>,
         calendarService: CalendarServiceProviding,
         dateProvider: DateProviding) {

        let calendar = Calendar.current

        // Calculate date range for current month
        let dateRangeObservable = dateObservable
            .compactMap { selectedDate in
                calendar.dateInterval(of: .month, for: selectedDate)?.start
            }
            .distinctUntilChanged()
            .map { firstDayOfMonth -> (start: Date, end: Date) in

                let currentWeekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let start = calendar.date(byAdding: .day, value: -currentWeekDay, to: firstDayOfMonth)!
                let end = calendar.date(byAdding: .day, value: 42, to: start)!

                return (start, end)
            }
            .share(replay: 1)

        // Get events for current date range
        let eventsObservable = Observable.combineLatest(
            dateRangeObservable, calendarService.changeObservable.startWith(())
        )
        .map(\.0)
        .map { start, end in
            calendarService.events(from: start, to: end)
        }

        // Clear hover when month changes
        let hoverObservable: Observable<Date?> = Observable.merge(
            dateRangeObservable.toVoid().map { nil }, hoverObservable
        )

        cellViewModelsObservable = Observable.combineLatest(
            dateObservable,
            dateRangeObservable.map(\.start),
            hoverObservable,
            eventsObservable
        )
        .map { (selectedDate, start, hoveredDate, events) in

            let today = dateProvider.today

            var cellViewModels = [CalendarCellViewModel]()

            for day in 0..<42 {
                let date = calendar.date(byAdding: .day, value: day, to: start)!
                let inMonth = calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isHovered = hoveredDate.map { hoveredDate in
                    calendar.isDate(hoveredDate, inSameDayAs: date)
                } ?? false
                let events = events.filter {
                    calendar.isDate(date, in: ($0.start, $0.end))
                }
                let viewModel = CalendarCellViewModel(
                    date: date,
                    inMonth: inMonth,
                    isToday: isToday,
                    isSelected: isSelected,
                    isHovered: isHovered,
                    events: events
                )
                cellViewModels.append(viewModel)
            }

            return cellViewModels
        }
        .share(replay: 1)
    }

    func asObservable() -> Observable<[CalendarCellViewModel]> {
        return cellViewModelsObservable
    }
}
