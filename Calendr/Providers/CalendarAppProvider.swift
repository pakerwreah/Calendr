//
//  CalendarAppProvider.swift
//  Calendr
//
//  Created by Paker on 14/06/2025.
//

protocol CalendarAppProviding {
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

    func url(for event: EventModel) -> URL? {
        let app = CalendarApp(rawValue: userDefaults.defaultCalendarApp) ?? .calendar

        switch app {
            case .notion where !event.type.isReminder:
                return notionAppURL(for: event)

            default:
                return calendarAppURL(for: event)
        }
    }

    func calendarAppURL(for event: EventModel) -> URL? {
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

    func notionAppURL(for event: EventModel) -> URL? {

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        dateFormatter.dateFormat = event.isAllDay ? "yyyy-MM-dd" : "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

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
