//
//  CalendarAppProvider.swift
//  Calendr
//
//  Created by Paker on 14/06/2025.
//

import Collections

protocol CalendarAppProviding {
    var dateProvider: DateProviding { get }
    var appleScriptRunner: ScriptRunner { get }

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode, using workspace: WorkspaceServiceProviding) async
    func open(_ event: EventModel, preferring app: CalendarApp, using workspace: WorkspaceServiceProviding) async
}

extension CalendarAppProviding {

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode, using workspace: WorkspaceServiceProviding) {
        Task {
            await open(app, at: date, mode: mode, using: workspace)
        }
    }

    func open(_ event: EventModel, preferring app: CalendarApp, using workspace: WorkspaceServiceProviding) {
        Task {
            await open(event, preferring: app, using: workspace)
        }
    }
}

class CalendarAppProvider: CalendarAppProviding {

    let dateProvider: DateProviding
    let appleScriptRunner: ScriptRunner

    init(dateProvider: DateProviding, appleScriptRunner: ScriptRunner) {
        self.dateProvider = dateProvider
        self.appleScriptRunner = appleScriptRunner
    }

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode, using workspace: WorkspaceServiceProviding) async {
        var date = date
        if mode == .week, let week = dateProvider.calendar.dateInterval(of: .weekOfYear, for: date) {
            date = week.start
        }
        switch app {
            case .calendar:
                await openCalendarApp(at: date, mode: mode, using: workspace)

            case .notion:
                await openNotionApp(at: date, mode: mode, using: workspace, retries: 1)
        }
    }

    func open(_ event: EventModel, preferring app: CalendarApp, using workspace: WorkspaceServiceProviding) async {
        switch app {
            case .calendar,
                 _ where !event.type.isEvent:

                await openCalendarApp(at: event, using: workspace)

            case .notion:
                await openNotionApp(at: event, using: workspace)
        }
    }

    // MARK: - Date Openers

    private func openCalendarApp(at date: Date, mode: CalendarViewMode, using workspace: WorkspaceServiceProviding) async {

        let calendarScript = CalendarScript(appleScriptRunner: appleScriptRunner)
        let ok = await calendarScript.openCalendar(at: date, mode: mode)
        if !ok {
            // If the script fails, just open the calendar.
            // There's no url api we can use to jump to a date.
            workspace.open(CalendarApp.calendar.baseURL)
        }
    }

    @MainActor
    private func openNotionApp(at date: Date, mode: CalendarViewMode, using workspace: WorkspaceServiceProviding, retries: Int = 0) async {

        let dateFormatter = DateFormatter(format: "yyyy/M/d", calendar: dateProvider.calendar)
        let path = "\(mode)/\(dateFormatter.string(from: date))"

        // Notion calendar handles deeplinks very poorly, specially on cold start.
        // If it needs to reload to show the chosen date, it completely misses.
        // We have to try a few times to "guarantee" we end up in the right place.
        for i in 0...retries {
            if i > 0 {
                await Task.sleep(seconds: 1)
            }
            if let url = CalendarApp.notion.deeplink(path: "\(path)?t=\(Date.now.timeIntervalSince1970)") {
                workspace.open(url)
            }
        }
    }

    // MARK: - Event Openers

    private func openCalendarApp(at event: EventModel, using workspace: WorkspaceServiceProviding) async {
        if let url = calendarAppEventURL(for: event) {
            workspace.open(url)
        }
    }

    private func openNotionApp(at event: EventModel, using workspace: WorkspaceServiceProviding) async {

        // if the event is not loaded, it will just fail, so we have to go to the date first
        await openNotionApp(at: event.start, mode: .day, using: workspace)

        // if the distance from the current date is too big, it will certainly try to load, so we wait a bit
        if abs(dateProvider.now.distance(to: event.start)) > 7889400 /* 3 months */ {
            await Task.sleep(seconds: 1)
        }

        if let url = notionAppEventURL(for: event) {
            workspace.open(url)
        }
    }

    // MARK: - Event URL builders

    private func calendarAppEventURL(for event: EventModel) -> URL? {
        guard let id = event.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }

        guard !event.type.isReminder else {
            return URL(string: "x-apple-reminderkit://remcdreminder/\(id)")
        }

        let dateFormatter = DateFormatter(format: "yyyyMMdd'T'HHmmss'Z'", calendar: dateProvider.calendar)

        let date: String
        if event.hasRecurrenceRules {
            if !event.isAllDay {
                dateFormatter.timeZone = .init(secondsFromGMT: 0)
            }
            if let formattedDate = dateFormatter.string(for: event.start) {
                date = "/\(formattedDate)"
            } else {
                return nil
            }
        } else {
            date = ""
        }
        return URL(string: "ical://ekevent\(date)/\(id)?method=show&options=more")
    }

    private func notionAppEventURL(for event: EventModel) -> URL? {

        let format = event.isAllDay ? "yyyy-MM-dd" : "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let dateFormatter = DateFormatter(format: format, calendar: dateProvider.calendar)

        guard
            let accountEmail = event.calendar.account.email,
            let startDate = dateFormatter.string(for: event.start),
            let endDate = dateFormatter.string(for: event.end)
        else {
            return nil
        }

        // remove recurrence identifier
        let iCalUID = event.externalId.replacingOccurrences(of: "/RID.+$", with: "", options: .regularExpression)

        let queryItems: OrderedDictionary<String, String?> = [
            "accountEmail": accountEmail,
            "iCalUID": iCalUID,
            "startDate": startDate,
            "endDate": endDate,
            "title": event.title,
            "ref": Bundle.main.bundleIdentifier,
        ]

        let params = queryItems.compactMap { (key, value) in
            if let value = value?.urlEncodedQueryItem {
                return "\(key)=\(value)"
            }
            return nil
        }.joined(separator: "&")

        return URL(string: "cron://showEvent?\(params)")
    }
}
