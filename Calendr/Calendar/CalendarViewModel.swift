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

        let dateObservable = dateObservable.distinctUntilChanged().share()

        // Calculate date range for current month
        let dateRangeObservable = dateObservable
            .compactMap { selectedDate in
                Calendar.current.dateInterval(of: .month, for: selectedDate)
            }
            .distinctUntilChanged()
            .share()

        // Create cells for current month
        let dateCellsObservable = dateRangeObservable.map { month -> [CalendarCellViewModel] in

            let today = dateProvider.today
            let currentWeekDay = Calendar.current.component(.weekday, from: month.start) - 1
            let start = Calendar.current.date(byAdding: .day, value: -currentWeekDay, to: month.start)!

            return (0..<42).map { day -> CalendarCellViewModel in
                let date = Calendar.current.date(byAdding: .day, value: day, to: start)!
                let inMonth = month.contains(date)
                let isToday = Calendar.current.isDate(date, inSameDayAs: today)

                return CalendarCellViewModel(
                    date: date,
                    inMonth: inMonth,
                    isToday: isToday,
                    isSelected: false,
                    isHovered: false,
                    events: []
                )
            }
        }
        .share()

        // Get events for current dates
        let eventsObservable = Observable.combineLatest(
            dateCellsObservable, calendarService.changeObservable.startWith(())
        )
        .map { cellViewModels, _ -> [CalendarCellViewModel] in

            let events = calendarService.events(
                from: cellViewModels.first!.date, to: cellViewModels.last!.date
            )

            return cellViewModels.map { viewModel in

                let events = events.filter {
                    Calendar.current.isDate(viewModel.date, in: ($0.start, $0.end))
                }

                return CalendarCellViewModel(
                    date: viewModel.date,
                    inMonth: viewModel.inMonth,
                    isToday: viewModel.isToday,
                    isSelected: false,
                    isHovered: false,
                    events: events
                )

            }
        }
        .share()

        // Check which cell is selected
        let isSelectedObservable = Observable.combineLatest(
            eventsObservable, dateObservable
        )
        .map { cellViewModels, selectedDate -> [CalendarCellViewModel] in

            cellViewModels.map { viewModel in

                let isSelected = Calendar.current.isDate(viewModel.date, inSameDayAs: selectedDate)

                return CalendarCellViewModel(
                    date: viewModel.date,
                    inMonth: viewModel.inMonth,
                    isToday: viewModel.isToday,
                    isSelected: isSelected,
                    isHovered: false,
                    events: viewModel.events
                )
            }
        }
        .share()

        // Clear hover when month changes
        let hoverObservable: Observable<Date?> = Observable.merge(
            dateRangeObservable.toVoid().map { nil }, hoverObservable
        )

        // Check which cell is hovered
        cellViewModelsObservable = Observable.combineLatest(
            isSelectedObservable, hoverObservable
        )
        .map { cellViewModels, hoveredDate -> [CalendarCellViewModel] in

            cellViewModels.map { viewModel in

                let isHovered = hoveredDate.map { date in
                    Calendar.current.isDate(date, inSameDayAs: viewModel.date)
                } ?? false

                return CalendarCellViewModel(
                    date: viewModel.date,
                    inMonth: viewModel.inMonth,
                    isToday: viewModel.isToday,
                    isSelected: viewModel.isSelected,
                    isHovered: isHovered,
                    events: viewModel.events
                )
            }
        }
        .share(replay: 1)
    }

    func asObservable() -> Observable<[CalendarCellViewModel]> {
        return cellViewModelsObservable
    }
}
