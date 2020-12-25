//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    init(yearObservable: Observable<Int>, monthObservable: Observable<Int>) {

        cellViewModelsObservable = Observable.combineLatest(yearObservable, monthObservable)
            .compactMap { year, month in
                let calendar = Calendar.current

                guard let firstDayOfMonth = calendar.date(
                    from: DateComponents(year: year, month: month)
                ) else { return nil }

                let currentWeekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let start = calendar.date(byAdding: .day, value: -currentWeekDay, to: firstDayOfMonth)!

                var cellViewModels = [CalendarCellViewModel]()

                for day in 0..<42 {
                    let date = calendar.date(byAdding: .day, value: day, to: start)!
                    let label = calendar.component(.day, from: date)
                    let inMonth = calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .month)
                    let isWeekend = calendar.isDateInWeekend(date)
                    let viewModel = CalendarCellViewModel(label: "\(label)",
                                                          inMonth: inMonth,
                                                          isWeekend: isWeekend,
                                                          events: Self.getEvents())
                    cellViewModels.append(viewModel)
                }

                return cellViewModels
            }
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
