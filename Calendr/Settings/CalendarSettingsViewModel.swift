//
//  CalendarSettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 01/08/2026.
//

import Foundation
import RxSwift

class CalendarSettingsViewModel {

    let title: String

    let showNextEventObserver: AnyObserver<Bool>
    let showNextEventTitleObserver: AnyObserver<Bool>
    let isHolidayCalendarObserver: AnyObserver<Bool>

    let showNextEvent: Observable<Bool>
    let showNextEventTitle: Observable<Bool>
    let isHolidayCalendar: Observable<Bool>

    let browserPickerViewModel: BrowserPickerViewModel

    init(
        calendar: CalendarModel,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider
    ) {
        title = calendar.title

        browserPickerViewModel = BrowserPickerViewModel(
            calendarId: calendar.id,
            workspace: workspace,
            localStorage: localStorage,
            source: .settings
        )

        showNextEvent = localStorage.rx.observe(\.silencedCalendars)
            .map { !$0.contains(calendar.id) }

        showNextEventTitle = localStorage.rx.observe(\.hiddenEventStatusItemTitleCalendars)
            .map { !$0.contains(calendar.id) }

        isHolidayCalendar = localStorage.rx.observe(\.holidayCalendars)
            .map { $0.contains(calendar.id) }

        showNextEventObserver = .init {
            guard let isEnabled = $0.element else { return }
            localStorage.silencedCalendars = updating(
                localStorage.silencedCalendars,
                identifier: calendar.id,
                included: !isEnabled
            )
        }

        showNextEventTitleObserver = .init {
            guard let isEnabled = $0.element else { return }
            localStorage.hiddenEventStatusItemTitleCalendars = updating(
                localStorage.hiddenEventStatusItemTitleCalendars,
                identifier: calendar.id,
                included: !isEnabled
            )
        }

        isHolidayCalendarObserver = .init {
            guard let isHoliday = $0.element else { return }
            localStorage.holidayCalendars = updating(
                localStorage.holidayCalendars,
                identifier: calendar.id,
                included: isHoliday
            )
        }
    }
}

private func updating(_ identifiers: [String], identifier: String, included: Bool) -> [String] {
    included ? identifiers + [identifier] : identifiers.filter { $0 != identifier }
}
