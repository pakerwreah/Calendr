//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    init(dateObservable: Observable<Date>) {

        cellViewModelsObservable = dateObservable.compactMap { selectedDate in
            let calendar = Calendar.current
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
                let viewModel = CalendarCellViewModel(day: day,
                                                      inMonth: inMonth,
                                                      isToday: isToday,
                                                      isSelected: isSelected,
                                                      events: Self.getEvents())
                cellViewModels.append(viewModel)
            }

            return cellViewModels
        }.share(replay: 1)
    }

    // TODO: get events from system calendar
    private static func getEvents() -> [Event] {
        let colors: [NSColor] = [.systemYellow, .systemRed, .systemGreen]
        return colors.compactMap {
            Bool.random() ? Event(color: $0) : nil
        }
    }

    func asObservable() -> Observable<[CalendarCellViewModel]> {
        return cellViewModelsObservable
    }
}
