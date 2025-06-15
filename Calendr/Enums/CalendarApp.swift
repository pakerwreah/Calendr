//
//  CalendarApp.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

enum CalendarApp: String, CaseIterable {
    case calendar, notion
}

extension CalendarApp {

    var scheme: String {
        switch self {
            case .calendar: "ical"
            case .notion: "cron"
        }
    }

    var baseURL: URL {
        URL(string: "\(scheme)://")!
    }

    func deeplink(path: String) -> URL? {
        URL(string: "\(scheme)://\(path)")
    }
}
