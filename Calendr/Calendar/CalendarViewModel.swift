//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import RxSwift

class CalendarViewModel {

    private let cellViewModelsObservable: Observable<[CalendarCellViewModel]>

    let title: Observable<String>
    let weekDays: Observable<[WeekDay]>
    let weekNumbers: Observable<[Int]>

    init(
        dateObservable: Observable<Date>,
        hoverObservable: Observable<Date?>,
        enabledCalendars: Observable<[String]>,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        notificationCenter: NotificationCenter
    ) {

        let calendarObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .toVoid()
            .startWith(())
            .map { dateProvider.calendar }
            .share(replay: 1)

        let dateFormatterObservable = calendarObservable
            .map(\.locale)
            .distinctUntilChanged()
            .map {
                DateFormatter(format: "MMM yyyy", locale: $0).with(context: .beginningOfSentence)
            }
            .share(replay: 1)

        let firstWeekdayObservable = calendarObservable
            .map(\.firstWeekday)
            .distinctUntilChanged()
            .share(replay: 1)

        title = Observable.combineLatest(
            dateFormatterObservable, dateObservable
        )
        .map { $0.string(from: $1) }
        .distinctUntilChanged()
        .share(replay: 1)

        weekDays = Observable.combineLatest(
            dateFormatterObservable, firstWeekdayObservable
        )
        .map { dateFormatter, firstWeekday in
            (firstWeekday ..< firstWeekday + 7)
                .map { ($0 - 1) % 7 }
                .map { weekDay in
                    WeekDay(
                        title: dateFormatter.veryShortWeekdaySymbols[weekDay],
                        isWeekend: [0, 6].contains(weekDay)
                    )
                }
        }
        .share(replay: 1)

        // Calculate date range for current month
        let dateRangeObservable = dateObservable
            .compactMap { selectedDate in
                dateProvider.calendar.dateInterval(of: .month, for: selectedDate)
            }
            .distinctUntilChanged()
            .share()

        // Create cells for current month
        let dateCellsObservable = Observable.combineLatest(
            dateRangeObservable, firstWeekdayObservable
        )
        .map { month, firstWeekday -> [CalendarCellViewModel] in

            let currentWeekDay = dateProvider.calendar.component(.weekday, from: month.start)
            let start = dateProvider.calendar.date(
                byAdding: .day,
                value: firstWeekday - currentWeekDay,
                to: month.start
            )!

            return (0..<42).map { day -> CalendarCellViewModel in
                let date = dateProvider.calendar.date(byAdding: .day, value: day, to: start)!
                let inMonth = dateProvider.calendar.isDate(date, equalTo: month.start, toGranularity: .month)

                return CalendarCellViewModel(
                    date: date,
                    inMonth: inMonth,
                    isToday: false,
                    isSelected: false,
                    isHovered: false,
                    events: nil
                )
            }
        }
        .share()

        weekNumbers = dateCellsObservable.map { dateCells in
            (0..<6).map {
                dateProvider.calendar.component(.weekOfYear, from: dateCells[7 * $0].date)
            }
        }
        .share(replay: 1)

        // Get events for current dates
        let eventsObservable = Observable.combineLatest(
            dateCellsObservable,
            enabledCalendars.startWith([]),
            calendarService.changeObservable.startWith(())
        )
        .flatMapLatest { cellViewModels, calendars, _ -> Observable<[EventModel]?> in

            calendarService.events(
                from: cellViewModels.first!.date,
                to: cellViewModels.last!.date,
                calendars: calendars
            )
            .toOptional()
            .startWith(nil)
        }
        .share()

        var timezone = dateProvider.calendar.timeZone

        // Check if today has changed
        let todayObservable = dateObservable
            .toVoid()
            .map { dateProvider.now }
            .distinctUntilChanged { a, b in
                timezone == dateProvider.calendar.timeZone && dateProvider.calendar.isDate(a, inSameDayAs: b)
            }
            .do(afterNext: { _ in
                timezone = dateProvider.calendar.timeZone
            })
            .share()

        // Check which cell is today
        let isTodayObservable = Observable.combineLatest(
            dateCellsObservable, eventsObservable, todayObservable
        )
        .map { cellViewModels, events, today -> [CalendarCellViewModel] in

            cellViewModels.map { vm in
                vm.with(
                    isToday: dateProvider.calendar.isDate(vm.date, inSameDayAs: today),
                    events: events?.filter { event in
                        dateProvider.calendar.isDate(vm.date, in: (event.start, event.end))
                    }
                )
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
