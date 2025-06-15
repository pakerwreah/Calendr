//
//  MockCalendarAppProvider.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

class MockCalendarAppProvider: CalendarAppProviding {

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode) { }

    func url(for event: EventModel) -> URL? { nil }
}
