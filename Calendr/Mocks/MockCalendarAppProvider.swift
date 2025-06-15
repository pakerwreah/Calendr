//
//  MockCalendarAppProvider.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

#if DEBUG

class MockCalendarAppProvider: CalendarAppProviding {
    let dateProvider: DateProviding
    let appleScriptRunner: ScriptRunner

    init(
        dateProvider: DateProviding = MockDateProvider(),
        appleScriptRunner: ScriptRunner = MockScriptRunner()
    ) {
        self.dateProvider = dateProvider
        self.appleScriptRunner = appleScriptRunner
    }

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode) { }

    func url(for event: EventModel) -> URL? { nil }
}

#endif
