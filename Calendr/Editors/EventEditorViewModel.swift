//
//  EventEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import AppKit
import Observation
import RxSwift

@Observation.Observable
class EventEditorViewModel: HostingWindowControllerDelegate {

    var title = ""
    var startDate: Date {
        didSet {
            guard !isSyncingDates, startDate != oldValue else { return }
            isSyncingDates = true
            defer { isSyncingDates = false }

            if isAllDay {
                guard calendar.isDate(endDate, lessThan: startDate, granularity: .day) else { return }
                endDate = startDate
            } else {
                endDate = startDate.addingTimeInterval(eventDuration)
            }
        }
    }
    var endDate: Date {
        didSet {
            guard !isSyncingDates, endDate != oldValue, !isAllDay else { return }
            guard endDate > startDate else { return }
            eventDuration = endDate.timeIntervalSince(startDate)
        }
    }
    var isAllDay = false {
        didSet {
            guard isAllDay != oldValue else { return }
            adjustDatesForAllDayChange()
        }
    }
    var location = ""
    var url = ""
    var notes = ""
    var selectedAlert: EventAlert = .none
    var selectedTimeZoneIdentifier: String {
        didSet {
            guard selectedTimeZoneIdentifier != oldValue else { return }
            preserveWallClockTime(
                from: TimeZone(identifier: oldValue) ?? dateProvider.calendar.timeZone
            )
        }
    }
    var isCloseConfirmationVisible = false
    var isErrorVisible = false

    private(set) var calendarSections: [CalendarSection] = []
    var selectedCalendarId: String?

    var selectedCalendarColor: NSColor {
        calendarSections
            .flatMap(\.calendars)
            .first { $0.id == selectedCalendarId }?
            .color ?? .clear
    }

    private(set) var error: UnexpectedError? {
        didSet {
            if error != nil {
                isErrorVisible = true
            }
        }
    }

    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let scheduler: ImmediateSchedulerType

    private let disposeBag = DisposeBag()

    private var eventDuration: TimeInterval = 3600
    private var isSyncingDates = false

    private var calendar: Calendar { dateProvider.calendar.with(timeZone: selectedTimeZone) }

    var selectedTimeZone: TimeZone {
        TimeZone(identifier: selectedTimeZoneIdentifier) ?? dateProvider.calendar.timeZone
    }

    init(startDate: DueDate, dateProvider: DateProviding, calendarService: CalendarServiceProviding, scheduler: ImmediateSchedulerType) {
        self.dateProvider = dateProvider
        let roundedStart = roundUpToNextHour(startDate.date, using: dateProvider)
        let defaultDuration: TimeInterval = 3600
        self.startDate = roundedStart
        self.eventDuration = defaultDuration
        self.endDate = roundedStart.addingTimeInterval(defaultDuration)
        self.calendarService = calendarService
        self.scheduler = scheduler
        self.selectedTimeZoneIdentifier = dateProvider.calendar.timeZone.identifier

        loadCalendars()
    }

    var onCloseConfirmed: (() -> Void)?

    func confirmClose() {
        isCloseConfirmationVisible = false
        onCloseConfirmed?()
    }

    func dismissError() {
        isErrorVisible = false
        error = nil
    }

    var parsedUrl: URL? {
        let trimmed = url.trimmed
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    var hasValidDateRange: Bool {
        if isAllDay {
            return calendar.isDate(endDate, greaterThanOrEqualTo: startDate, granularity: .day)
        }
        return endDate > startDate
    }

    var hasValidInput: Bool {
        !title.trimmed.isEmpty && hasValidDateRange && selectedCalendarId != nil
    }

    var hasUnsavedChanges: Bool {
        [title, location, url, notes].contains(where: \.trimmed.isEmpty.isFalse)
    }

    func saveEvent() {
        guard hasValidInput, let selectedCalendarId else { return }

        let trimmedLocation = location.trimmed
        let trimmedNotes = notes.trimmed

        calendarService.createEvent(
            title: title.trimmed,
            calendar: selectedCalendarId,
            start: startDate,
            end: endDate,
            isAllDay: isAllDay,
            location: trimmedLocation.isEmpty ? nil : trimmedLocation,
            url: parsedUrl,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            alertOffset: selectedAlert.relativeOffset,
            timeZone: selectedTimeZone
        )
        .observe(on: scheduler)
        .subscribe(onCompleted: { [weak self] in
            self?.confirmClose()
        }, onError: { [weak self] error in
            self?.error = error.unexpected
        })
        .disposed(by: disposeBag)
    }

    func requestWindowClose() -> Bool {
        if hasUnsavedChanges {
            isCloseConfirmationVisible = true
        }
        return !isCloseConfirmationVisible
    }

    // MARK: - Private

    private func preserveWallClockTime(from oldTimeZone: TimeZone) {
        let newTimeZone = selectedTimeZone
        guard oldTimeZone != newTimeZone else { return }
        isSyncingDates = true
        defer { isSyncingDates = false }

        let oldCalendar = dateProvider.calendar.with(timeZone: oldTimeZone)
        let newCalendar = dateProvider.calendar.with(timeZone: newTimeZone)

        let components: Set<Calendar.Component> = isAllDay
            ? [.year, .month, .day]
            : [.year, .month, .day, .hour, .minute, .second]

        let startComponents = oldCalendar.dateComponents(components, from: startDate)
        let endComponents = oldCalendar.dateComponents(components, from: endDate)

        startDate = newCalendar.date(from: startComponents) ?? startDate
        endDate = newCalendar.date(from: endComponents) ?? endDate
    }

    private func adjustDatesForAllDayChange() {
        isSyncingDates = true
        defer { isSyncingDates = false }

        if isAllDay {
            startDate = calendar.startOfDay(for: startDate)
            endDate = calendar.startOfDay(for: endDate)
            if calendar.isDate(endDate, lessThan: startDate, granularity: .day) {
                endDate = startDate
            }
        } else if endDate <= startDate {
            endDate = startDate.addingTimeInterval(eventDuration)
        }
    }

    private func loadCalendars() {

        calendarService.calendars(forNew: .event)
            .observe(on: scheduler)
            .subscribe(onSuccess: { [weak self] calendars in
                self?.setupCalendars(calendars)
            }, onFailure: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)
    }

    private func setupCalendars(_ calendars: [CalendarModel]) {

        calendarSections = calendars.groupedByAccount()

        let defaultId = calendarService.defaultCalendar(forNew: .event)?.id

        if let defaultId, calendars.contains(where: { $0.id == defaultId }) {
            selectedCalendarId = defaultId
        } else if let first = calendarSections.first?.calendars.first {
            selectedCalendarId = first.id
        }
    }
}

private func roundUpToNextHour(_ date: Date, using dateProvider: DateProviding) -> Date {
    let calendar = dateProvider.calendar
    guard let interval = calendar.dateInterval(of: .hour, for: date) else { return date }
    if date == interval.start { return date }
    return calendar.date(byAdding: .hour, value: 1, to: interval.start)!
}
