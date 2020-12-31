//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    init(dateObservable: Observable<Date>, calendarService: CalendarServiceProviding) {

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

        cellViewModelsObservable = Observable.combineLatest(
            dateObservable, eventsObservable
        )
        .map { selectedDate, events in

            let currentDate = Date()
            let firstDayOfMonth = calendar.dateInterval(of: .month, for: selectedDate)!.start
            let currentWeekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
            let start = calendar.date(byAdding: .day, value: -currentWeekDay, to: firstDayOfMonth)!

            var cellViewModels = [CalendarCellViewModel]()

            for day in 0..<42 {
                let date = calendar.date(byAdding: .day, value: day, to: start)!
                let day = calendar.component(.day, from: date)
                let inMonth = calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .month)
                let isToday = calendar.isDate(date, inSameDayAs: currentDate)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let events = events.filter {
                    calendar.isDate(date, in: ($0.start, $0.end), toGranularity: .day)
                }
                let viewModel = CalendarCellViewModel(day: day,
                                                      inMonth: inMonth,
                                                      isToday: isToday,
                                                      isSelected: isSelected,
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
