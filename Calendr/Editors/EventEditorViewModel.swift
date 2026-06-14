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
    var startDate: Date
    var endDate: Date
    var isAllDay = false {
        didSet {
            guard isAllDay != oldValue else { return }
            adjustDatesForAllDayChange()
        }
    }
    var location = ""
    var url = ""
    var notes = ""
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

    private let disposeBag = DisposeBag()

    private var calendar: Calendar { dateProvider.calendar }

    init(startDate: DueDate, dateProvider: DateProviding, calendarService: CalendarServiceProviding) {
        self.dateProvider = dateProvider
        self.startDate = startDate.date
        self.endDate = dateProvider.calendar.date(byAdding: .hour, value: 1, to: startDate.date)!
        self.calendarService = calendarService

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
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        .observe(on: MainScheduler.instance)
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

    private func adjustDatesForAllDayChange() {
        if isAllDay {
            startDate = calendar.startOfDay(for: startDate)
            endDate = calendar.startOfDay(for: endDate)
            if calendar.isDate(endDate, lessThan: startDate, granularity: .day) {
                endDate = startDate
            }
        } else if endDate <= startDate {
            endDate = calendar.date(byAdding: .hour, value: 1, to: startDate)!
        }
    }

    private func loadCalendars() {

        calendarService.calendars(forNew: .event)
            .observe(on: MainScheduler.instance)
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
