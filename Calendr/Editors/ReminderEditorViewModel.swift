//
//  ReminderEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import AppKit
import Observation
import RxSwift

struct CalendarSection: Equatable {
    let title: String
    let calendars: [CalendarModel]
}

@Observation.Observable
class ReminderEditorViewModel: HostingWindowControllerDelegate {
    
    var title = ""
    var dueDate: Date
    var isAllDay = false
    var isCloseConfirmationVisible = false
    var isErrorVisible = false

    private(set) var calendarSections: [CalendarSection] = []
    var selectedCalendarId: String = ""

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

    private let disposeBag = DisposeBag()

    init(dueDate: DueDate, calendarService: CalendarServiceProviding) {
        self.dueDate = dueDate.date
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

    var hasValidInput: Bool {
        !title.trimmed.isEmpty
    }

    func saveReminder() {
        guard hasValidInput, !selectedCalendarId.isEmpty else { return }

        calendarService.createReminder(title: title, calendar: selectedCalendarId, date: dueDate, isAllDay: isAllDay)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.confirmClose()
            }, onError: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)
    }

    func requestWindowClose() -> Bool {
        if hasValidInput {
            isCloseConfirmationVisible = true
        }
        return !isCloseConfirmationVisible
    }

    // MARK: - Private

    private func loadCalendars() {

        calendarService.calendars(forNew: .reminder)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] calendars in
                self?.setupCalendars(calendars)
            })
            .disposed(by: disposeBag)
    }

    private func setupCalendars(_ calendars: [CalendarModel]) {

        func isOther(_ account: String) -> Bool {
            account == Strings.Calendars.Source.others
        }

        calendarSections = Dictionary(grouping: calendars, by: \.account.title)
            .sorted {
                if isOther($0.key) && !isOther($1.key) { return false }
                if !isOther($0.key) && isOther($1.key) { return true }
                return $0.key.localizedLowercase < $1.key.localizedLowercase
            }
            .map { CalendarSection(title: $0.key, calendars: $0.value.sorted(by: \.title.localizedLowercase)) }

        let defaultId = calendarService.defaultCalendar(forNew: .reminder)?.id

        if let defaultId, calendars.contains(where: { $0.id == defaultId }) {
            selectedCalendarId = defaultId
        } else if let first = calendars.first {
            selectedCalendarId = first.id
        }
    }
}
