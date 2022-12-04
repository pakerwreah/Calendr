//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Foundation
import RxSwift

class CalendarViewModel {

    let cellViewModelsObservable: Observable<[CalendarCellViewModel]>
    let focusedEventsObservable: Observable<(Date, [EventModel])>

    let title: Observable<String>
    let weekDays: Observable<[WeekDay]>
    let weekNumbers: Observable<[Int]?>
    let calendarScaling: Observable<Double>
    let cellSize: Observable<Double>
    let weekNumbersWidth: Observable<Double>

    init(
        searchObservable: Observable<String>,
        dateObservable: Observable<Date>,
        hoverObservable: Observable<Date?>,
        enabledCalendars: Observable<[String]>,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        settings: CalendarSettings,
        notificationCenter: NotificationCenter
    ) {

        let calendarObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()
            .startWith(())
            .map { dateProvider.calendar }
            .share(replay: 1)

        let dateFormatterObservable = calendarObservable
            .distinctUntilChanged()
            .map {
                DateFormatter(format: "MMM yyyy", calendar: $0).with(context: .beginningOfSentence)
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
            .share(replay: 1)

        // Create cells for current month
        let dateCellsObservable = Observable.combineLatest(
            dateRangeObservable, firstWeekdayObservable
        )
        .map { month, firstWeekday -> [CalendarCellViewModel] in

            let monthStartWeekDay = dateProvider.calendar.component(.weekday, from: month.start)

            let start = dateProvider.calendar.date(
                byAdding: .day,
                value: { $0 <= 0 ? $0 : $0 - 7 }(firstWeekday - monthStartWeekDay),
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
                    events: [],
                    calendar: dateProvider.calendar
                )
            }
        }
        .share(replay: 1)

        weekNumbers = Observable.combineLatest(
            settings.showWeekNumbers, dateCellsObservable
        )
        .map { showWeekNumbers, dateCells in
            !showWeekNumbers ? nil : (0..<6).map {
                dateProvider.calendar.component(.weekOfYear, from: dateCells[7 * $0].date)
            }
        }
        .share(replay: 1)

        // Get events for current dates
        let eventsObservable = Observable.combineLatest(
            dateCellsObservable,
            enabledCalendars.startWith([])
        )
        .repeat(when: calendarService.changeObservable)
        .flatMapLatest { cellViewModels, calendars -> Observable<[EventModel]> in

            guard let endOfLastDate = dateProvider.calendar.date(
                bySettingHour: 23, minute: 59, second: 59,
                of: cellViewModels.last!.date
            ) else { return .empty() }

            return calendarService.events(
                from: cellViewModels.first!.date,
                to: endOfLastDate,
                calendars: calendars
            )
        }
        .distinctUntilChanged()
        .share(replay: 1)

        let filteredEventsObservable = Observable.combineLatest(
            eventsObservable,
            settings.showDeclinedEvents,
            searchObservable
        )
        .map { events, showDeclinedEvents, searchTerm in
            events.filter {
                (showDeclinedEvents || $0.status != .declined)
                &&
                (searchTerm.isEmpty || $0.contains(searchTerm))
            }
        }
        .optional()
        .startWith(nil)
        .distinctUntilChanged()
        .share(replay: 1)

        var timezone = dateProvider.calendar.timeZone

        // Check if today has changed
        let todayObservable = dateObservable
            .void()
            .map { dateProvider.now }
            .distinctUntilChanged { a, b in
                timezone == dateProvider.calendar.timeZone && dateProvider.calendar.isDate(a, inSameDayAs: b)
            }
            .do(afterNext: { _ in
                timezone = dateProvider.calendar.timeZone
            })
            .share(replay: 1)

        // Check which cell is today
        let isTodayObservable = Observable.combineLatest(
            dateCellsObservable, filteredEventsObservable, todayObservable
        )
        .map { cellViewModels, events, today -> [CalendarCellViewModel] in

            cellViewModels.map { vm in
                vm.with(
                    isToday: dateProvider.calendar.isDate(vm.date, inSameDayAs: today),
                    events: events?.filter { event in
                        dateProvider.calendar.isDate(vm.date, in: (event.start, event.end))
                    },
                    calendar: dateProvider.calendar
                )
            }
        }
        .share(replay: 1)

        // Check which cell is selected
        let isSelectedObservable = Observable.combineLatest(
            isTodayObservable, dateObservable
        )
        .map { cellViewModels, selectedDate -> [CalendarCellViewModel] in

            cellViewModels.map {
                $0.with(
                    isSelected: dateProvider.calendar.isDate($0.date, inSameDayAs: selectedDate),
                    calendar: dateProvider.calendar
                )
            }
        }
        .distinctUntilChanged()
        .share(replay: 1)

        // Clear hover when month changes
        let hoverObservable: Observable<Date?> = Observable.merge(
            dateRangeObservable.map(nil), hoverObservable
        )

        // Check which cell is hovered
        cellViewModelsObservable = Observable.combineLatest(
            isSelectedObservable, hoverObservable
        )
        .map { cellViewModels, hoveredDate -> [CalendarCellViewModel] in

            if let hoveredDate = hoveredDate {
                return cellViewModels.map {
                    $0.with(
                        isHovered: dateProvider.calendar.isDate($0.date, inSameDayAs: hoveredDate),
                        calendar: dateProvider.calendar
                    )
                }
            } else {
                return cellViewModels.map {
                    $0.with(isHovered: false, calendar: dateProvider.calendar)
                }
            }
        }
        .distinctUntilChanged()
        .share(replay: 1)

        calendarScaling = settings.calendarScaling

        cellSize = calendarScaling
            .map { Constants.cellSize * $0 + 10 * ($0 - 1) }
            .distinctUntilChanged()
            .share(replay: 1)

        weekNumbersWidth = Observable
            .combineLatest(weekNumbers, cellSize)
            .map { $0 != nil ? $1 * Constants.weekNumberCellRatio : 0 }
            .distinctUntilChanged()
            .share(replay: 1)

        focusedEventsObservable = cellViewModelsObservable
            .compactMap { [dateProvider] dates in
                guard
                    let focused = dates.first(where: \.isHovered) ?? dates.first(where: \.isSelected)
                else { return nil }

                guard focused.isToday else { return (focused.date, focused.events) }

                let overdue = dates
                    .filter { dateProvider.calendar.isDate($0.date, lessThan: dateProvider.now, granularity: .day) }
                    .flatMap(\.events)
                    .filter(\.type.isReminder)

                return (focused.date, overdue + focused.events)
            }
            .distinctUntilChanged(==)
            .share(replay: 1)
    }
}

private extension CalendarCellViewModel {

    func with(
        isToday: Bool? = nil,
        isSelected: Bool? = nil,
        isHovered: Bool? = nil,
        events: [EventModel]? = nil,
        calendar: Calendar
    ) -> Self {

        CalendarCellViewModel(
            date: date,
            inMonth: inMonth,
            isToday: isToday ?? self.isToday,
            isSelected: isSelected ?? self.isSelected,
            isHovered: isHovered ?? self.isHovered,
            events: events ?? self.events,
            calendar: calendar
        )
    }
}

private enum Constants {

    static let cellSize: CGFloat = 25
    static let weekNumberCellRatio: CGFloat = 0.85
}

private extension EventModel {

    func contains(_ searchTerm: String) -> Bool {
        [
            title,
            location,
            url?.absoluteString,
            notes,
            participants.map(\.name).joined(separator: " ")
        ]
        .contains { $0?.localizedCaseInsensitiveContains(searchTerm) ?? false }
    }
}
