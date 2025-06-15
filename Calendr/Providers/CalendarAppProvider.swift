//
//  CalendarAppProvider.swift
//  Calendr
//
//  Created by Paker on 14/06/2025.
//

protocol CalendarAppProviding {
    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode)
    func url(for event: EventModel) -> URL?
}

class CalendarAppProvider: CalendarAppProviding {

    private let userDefaults: UserDefaults
    private let dateProvider: DateProviding
    private let workspace: WorkspaceServiceProviding

    init(userDefaults: UserDefaults, dateProvider: DateProviding, workspace: WorkspaceServiceProviding) {
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
        self.workspace = workspace
    }

    // MARK: - Protocol

    func open(_ app: CalendarApp, at date: Date, mode: CalendarViewMode) {
        var date = date
        if mode == .week, let week = dateProvider.calendar.dateInterval(of: .weekOfYear, for: date) {
            date = week.start
        }
        switch app {
            case .calendar:
                Task {
                    let calendarScript = CalendarScript(workspace: workspace)
                    let ok = await calendarScript.openCalendar(at: date, mode: mode)
                    if !ok {
                        // If the script fails, just open the calendar.
                        // There's no url api we can use to jump to a date.
                        workspace.open(app.baseURL)
                    }
                }
            case .notion:
                let dateFormatter = DateFormatter(format: "yyyy/M/d", calendar: dateProvider.calendar)
                let path = "\(mode)/\(dateFormatter.string(from: date))"

                // Notion calendar handles deeplinks very poorly, specially on cold start.
                // If it needs to reload to show the chosen date, it completely misses.
                // We have to try a few times to "guarantee" we end up in the right place.
                for i in 0...3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(i)) { [workspace] in
                        if let url = app.deeplink(path: "\(path)?t=\(Date.now.timeIntervalSince1970)") {
                            workspace.open(url)
                        }
                    }
                }
        }
    }

    func url(for event: EventModel) -> URL? {
        let app = CalendarApp(rawValue: userDefaults.defaultCalendarApp) ?? .calendar

        switch app {
            case .notion where !event.type.isReminder:
                return notionAppURL(for: event)

            default:
                return calendarAppURL(for: event)
        }
    }

    // MARK: - URL builders

    private func calendarAppURL(for event: EventModel) -> URL? {
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

    private func notionAppURL(for event: EventModel) -> URL? {

        let format = event.isAllDay ? "yyyy-MM-dd" : "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let dateFormatter = DateFormatter(format: format, calendar: dateProvider.calendar)

        guard
            let accountEmail = event.calendar.account.email,
            let startDate = dateFormatter.string(for: event.start),
            let endDate = dateFormatter.string(for: event.end)
        else {
            return calendarAppURL(for: event)
        }

        // remove recurrence identifier
        let iCalUID = event.externalId.replacingOccurrences(of: "/RID.+$", with: "", options: .regularExpression)

        let queryItems: [String: String?] = [
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
