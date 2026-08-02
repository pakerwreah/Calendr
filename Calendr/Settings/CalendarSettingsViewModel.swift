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

    let showNextEvent: Observable<Bool>
    let showNextEventTitle: Observable<Bool>

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

        showNextEventObserver = .init {
            guard let isEnabled = $0.element else { return }
            localStorage.silencedCalendars = updating(
                localStorage.silencedCalendars,
                identifier: calendar.id,
                isEnabled: isEnabled
            )
        }

        showNextEventTitleObserver = .init {
            guard let isEnabled = $0.element else { return }
            localStorage.hiddenEventStatusItemTitleCalendars = updating(
                localStorage.hiddenEventStatusItemTitleCalendars,
                identifier: calendar.id,
                isEnabled: isEnabled
            )
        }
    }
}

private func updating(_ identifiers: [String], identifier: String, isEnabled: Bool) -> [String] {
    isEnabled ? identifiers.filter { $0 != identifier } : identifiers + [identifier]
}
