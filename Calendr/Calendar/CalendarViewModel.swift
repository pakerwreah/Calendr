//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import AppKit
import RxSwift

class CalendarViewModel {

    let cellViewModelsObservable: Observable<[CalendarCellViewModel]>
    let focusedDateEventsObservable: Observable<(Date, [EventModel])>

    let title: Observable<String>
    let weekCount: Observable<Int>
    let weekDays: Observable<[WeekDay]>
    let weekNumbers: Observable<[Int]?>
    let calendarScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>
    let cellSize: Observable<Double>
    let weekNumbersWidth: Observable<Double>

    init(
        searchObservable: Observable<String>,
        dateObservable: Observable<Date>,
        hoverObservable: Observable<Date?>,
        keyboardModifiers: Observable<NSEvent.ModifierFlags>,
        enabledCalendars: Observable<[String]>,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        settings: CalendarSettings,
        scheduler: SchedulerType
    ) {
        let calendarUpdated = dateProvider.calendarUpdated
            .startWith(dateProvider.calendar)
            .share(replay: 1)

        let dateFormatterObservable = calendarUpdated
            .map { calendar in
                DateFormatter(format: "MMM yyyy", calendar: calendar).with(context: .beginningOfSentence)
            }
            .share(replay: 1)

        title = Observable.combineLatest(
            dateFormatterObservable, dateObservable
        )
        .map { $0.string(from: $1) }
        .distinctUntilChanged()
        .share(replay: 1)

        weekDays = Observable
            .combineLatest(settings.highlightedWeekdays, calendarUpdated)
            .map { highlightedWeekdays, calendar in
                let firstWeekday = calendar.firstWeekday

                return (firstWeekday ..< firstWeekday + 7)
                    .map {
                        let weekDay = ($0 - 1) % 7
                        return WeekDay(
                            title: calendar.veryShortWeekdaySymbols[weekDay],
                            isHighlighted: highlightedWeekdays.contains(weekDay),
                            index: weekDay
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

        let debouncedWeekCount = settings.weekCount.debounce(.milliseconds(300), scheduler: scheduler)

        // Create cells for current month
        let dateCellsObservable = Observable
            .combineLatest(
                debouncedWeekCount,
                dateRangeObservable,
                calendarUpdated,
                settings.eventDotsStyle
            )
            .map { weeksCount, month, calendar, dotsStyle -> [CalendarCellViewModel] in

                let monthStartWeekDay = calendar.component(.weekday, from: month.start)

                let start = calendar.date(
                    byAdding: .day,
                    value: { $0 <= 0 ? $0 : $0 - 7 }(calendar.firstWeekday - monthStartWeekDay),
                    to: month.start
                )!

                return (0..<weeksCount * 7).map { day -> CalendarCellViewModel in
                    let date = calendar.date(byAdding: .day, value: day, to: start)!
                    let inMonth = calendar.isDate(date, equalTo: month.start, toGranularity: .month)

                    return CalendarCellViewModel(
                        date: date,
                        inMonth: inMonth,
                        isToday: false,
                        isSelected: false,
                        isHovered: false,
                        events: [],
                        dotsStyle: dotsStyle,
                        calendar: calendar
                    )
                }
            }
            .share(replay: 1)

        weekNumbers = Observable.combineLatest(
            settings.showWeekNumbers, dateCellsObservable
        )
        .map { showWeekNumbers, dateCells in
            !showWeekNumbers ? nil : (0..<dateCells.count / 7).map {
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
        .flatMapLatest { cellViewModels, calendars -> Single<[EventModel]> in

            calendarService.events(
                from: dateProvider.calendar.startOfDay(for: cellViewModels.first!.date),
                to: dateProvider.calendar.endOfDay(for: cellViewModels.last!.date),
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
                (searchTerm.isEmpty || $0.propertiesContain(searchTerm))
            }
        }
        .optional()
        .startWith(nil)
        .distinctUntilChanged()
        .share(replay: 1)

        var timeZone = dateProvider.calendar.timeZone

        // Check if today has changed
        let todayObservable = dateObservable
            .void()
            .map { dateProvider.now }
            .distinctUntilChanged { a, b in
                timeZone == dateProvider.calendar.timeZone && dateProvider.calendar.isDate(a, inSameDayAs: b)
            }
            .do(afterNext: { _ in
                timeZone = dateProvider.calendar.timeZone
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
                        dateProvider.calendar.isDay(vm.date, inDays: (event.start, event.end))
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
            isSelectedObservable, hoverObservable, keyboardModifiers, settings.dateHoverOption
        )
        .map { cellViewModels, hoveredDate, keyboardModifiers, dateHoverOption -> [CalendarCellViewModel] in

            if let hoveredDate, !dateHoverOption || keyboardModifiers.contains(.option) {
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

        weekCount = cellViewModelsObservable.map { $0.count / 7 }.distinctUntilChanged()

        calendarScaling = settings.calendarScaling
        calendarTextScaling = settings.calendarTextScaling

        cellSize = calendarScaling
            .map { Constants.cellSize * $0 + 10 * ($0 - 1) }
            .distinctUntilChanged()
            .share(replay: 1)

        weekNumbersWidth = Observable
            .combineLatest(weekNumbers, cellSize)
            .map { $0 != nil ? $1 * Constants.weekNumberCellRatio : 0 }
            .distinctUntilChanged()
            .share(replay: 1)

        focusedDateEventsObservable = cellViewModelsObservable
            .compactMap { dates in
                guard
                    let focused = dates.first(where: \.isHovered) ?? dates.first(where: \.isSelected)
                else { return nil }

                guard focused.isToday else { return (focused.date, focused.events) }

                let overdue = dates
                    .filter { dateProvider.calendar.isDate($0.date, lessThan: dateProvider.now, granularity: .day) }
                    .flatMap(\.events)
                    .filter { $0.type == .reminder(completed: false) }

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
            dotsStyle: dotsStyle,
            calendar: calendar
        )
    }
}

private enum Constants {

    static let cellSize: CGFloat = 25
    static let weekNumberCellRatio: CGFloat = 0.85
}

private extension EventModel {

    func propertiesContain(_ searchTerm: String) -> Bool {

        let searchTerm = searchTerm.trimmingCharacters(in: .whitespaces)

        return [
            title,
            location,
            url?.absoluteString,
            notes,
            participants.map(\.name).joined(separator: " ")
        ]
        .contains {
            $0?.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
