//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    let cellViewModelsObservable: Observable<[[CalendarCellViewModel]]>

    init(yearObservable: Observable<Int>, monthObservable: Observable<Int>) {

        cellViewModelsObservable = Observable.combineLatest(yearObservable, monthObservable)
            .compactMap { year, month in
                let calendar = Calendar.current

                guard let firstDayOfMonth = calendar.date(
                    from: DateComponents(year: year, month: month)
                ) else { return nil }

                let weekDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let start = calendar.date(byAdding: .day, value: -weekDay, to: firstDayOfMonth)!

                var cellViewModels = [[CalendarCellViewModel]]()

                for week in 0..<6 {
                    var rowViewModels = [CalendarCellViewModel]()
                    for dow in 0..<7 {
                        let date = calendar.date(byAdding: .day, value: 7 * week + dow, to: start)!
                        let label = calendar.component(.day, from: date)
                        let viewModel = CalendarCellViewModel(label: "\(label)", events: Self.getEvents())
                        rowViewModels.append(viewModel)
                    }
                    cellViewModels.append(rowViewModels)
                }

                return cellViewModels
            }
    }

    // TODO: get events from system calendar
    private static func getEvents() -> [Event] {
        let colors: [NSColor] = [.yellow, .red, .green]
        return colors.compactMap {
            Bool.random() ? Event(color: $0) : nil
        }
    }
}
