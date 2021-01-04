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
         hoverObservable: Observable<(date: Date, isHovered: Bool)>,
         calendarService: CalendarServiceProviding) {

        let calendar = Calendar.current

        let dateRangeObservable = dateObservable
            .map { selectedDate -> (start: Date, end: Date) in

                let firstDayOfMonth = calendar.dateInterval(of: .month, for: selectedDate)!.start
                let currentWeekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let start = calendar.date(byAdding: .day, value: -currentWeekDay, to: firstDayOfMonth)!
                let end = calendar.date(byAdding: .day, value: 42, to: start)!

                return (start: start, end: end)

            }
            .distinctUntilChanged { a, b -> Bool in
                a.start == b.start && a.end == b.end
            }


        let eventsObservable = Observable.combineLatest(
            dateRangeObservable, calendarService.changeObservable
        )
        .map { dateRange, _ in
            calendarService.events(from: dateRange.start, to: dateRange.end)
        }
        .startWith([])

        let hoverObservable = hoverObservable
            .debounce(.milliseconds(1), scheduler: MainScheduler.instance)
            .startWith((date: Date(), isHovered: false))

        cellViewModelsObservable = Observable.combineLatest(
            dateObservable, hoverObservable, eventsObservable
        )
        .map { selectedDate, hoveredDate, events in

            let currentDate = Date()
            let firstDayOfMonth = calendar.dateInterval(of: .month, for: selectedDate)!.start
            let currentWeekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
            let start = calendar.date(byAdding: .day, value: -currentWeekDay, to: firstDayOfMonth)!

            var cellViewModels = [CalendarCellViewModel]()

            for day in 0..<42 {
                let date = calendar.date(byAdding: .day, value: day, to: start)!
                let inMonth = calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .month)
                let isToday = calendar.isDate(date, inSameDayAs: currentDate)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isHovered = hoveredDate.isHovered && calendar.isDate(date, inSameDayAs: hoveredDate.date)
                let events = events.filter {
                    calendar.isDate(date, in: ($0.start, $0.end))
                }
                let viewModel = CalendarCellViewModel(date: date,
                                                      inMonth: inMonth,
                                                      isToday: isToday,
                                                      isSelected: isSelected,
                                                      isHovered: isHovered,
                                                      events: events)
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
