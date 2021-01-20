//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {
    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    init(
        dateObservable: Observable<Date>,
        hoverObservable: Observable<Date?>,
        enabledCalendars: Observable<[String]>,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding = DateProvider()
    ) {

        // Calculate date range for current month
        let dateRangeObservable = dateObservable
            .compactMap { selectedDate in
                dateProvider.calendar.dateInterval(of: .month, for: selectedDate)
            }
            .distinctUntilChanged()
            .share()

        // Create cells for current month
        let dateCellsObservable = dateRangeObservable.map { month -> [CalendarCellViewModel] in

            let currentWeekDay = dateProvider.calendar.component(.weekday, from: month.start) - 1
            let start = dateProvider.calendar.date(byAdding: .day, value: -currentWeekDay, to: month.start)!

            return (0..<42).map { day -> CalendarCellViewModel in
                let date = dateProvider.calendar.date(byAdding: .day, value: day, to: start)!
                let inMonth = month.contains(date)

                return CalendarCellViewModel(
                    date: date,
                    inMonth: inMonth,
                    isToday: false,
                    isSelected: false,
                    isHovered: false,
                    events: []
                )
            }
        }
        .share()

        // Get events for current dates
        let eventsObservable = Observable.combineLatest(
            dateCellsObservable,
            enabledCalendars.startWith([]),
            calendarService.changeObservable.startWith(())
        )
        .map { cellViewModels, calendars, _ -> [CalendarCellViewModel] in

            let events = calendarService.events(
                from: cellViewModels.first!.date,
                to: cellViewModels.last!.date,
                calendars: calendars
            )

            return cellViewModels.map { vm in
                vm.with(events: events.filter {
                    dateProvider.calendar.isDate(vm.date, in: ($0.start, $0.end))
                })
            }
        }
        .share()

        var timezone = dateProvider.calendar.timeZone

        // Check if today has changed
        let todayObservable = dateObservable
            .toVoid()
            .map { dateProvider.today }
            .distinctUntilChanged { a, b in
                timezone == dateProvider.calendar.timeZone && dateProvider.calendar.isDate(a, inSameDayAs: b)
            }
            .do(afterNext: { _ in
                timezone = dateProvider.calendar.timeZone
            })

        // Check which cell is today
        let isTodayObservable = Observable.combineLatest(
            eventsObservable, todayObservable
        )
        .map { cellViewModels, today -> [CalendarCellViewModel] in

            cellViewModels.map {
                $0.with(isToday: dateProvider.calendar.isDate($0.date, inSameDayAs: today))
            }
        }
        .share()

        // Check which cell is selected
        let isSelectedObservable = Observable.combineLatest(
            isTodayObservable, dateObservable
        )
        .map { cellViewModels, selectedDate -> [CalendarCellViewModel] in

            cellViewModels.map {
                $0.with(isSelected: dateProvider.calendar.isDate($0.date, inSameDayAs: selectedDate))
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

            if let hoveredDate = hoveredDate {
                return cellViewModels.map {
                    $0.with(isHovered: dateProvider.calendar.isDate($0.date, inSameDayAs: hoveredDate))
                }
            } else {
                return cellViewModels.map {
                    $0.with(isHovered: false)
                }
            }
        }
        .share(replay: 1)
    }

    func asObservable() -> Observable<[CalendarCellViewModel]> {
        return cellViewModelsObservable
    }
}

private extension CalendarCellViewModel {

    func with(
        isToday: Bool? = nil,
        isSelected: Bool? = nil,
        isHovered: Bool? = nil,
        events: [EventModel]? = nil
    ) -> Self {

        CalendarCellViewModel(
            date: date,
            inMonth: inMonth,
            isToday: isToday ?? self.isToday,
            isSelected: isSelected ?? self.isSelected,
            isHovered: isHovered ?? self.isHovered,
            events: events ?? self.events
        )
    }
}
