//
//  EventLink.swift
//  Calendr
//
//  Created by Paker on 04/06/22.
//

import Foundation

struct EventLink: Equatable {
    let url: URL
    let original: URL
    let isMeeting: Bool
    let calendarId: String
}

extension EventLink {

    var isNative: Bool {
        guard let scheme = url.scheme else { return false }
        return !["http", "https"].contains(scheme)
    }
}

extension EventModel {

    func detectLink(using workspace: WorkspaceServiceProviding) -> EventLink? {

        let links = !type.isBirthday
            ? detectLinks([location, url?.absoluteString, notes])
            : []

        if let (url, original) = links.lazy.compactMap({ url in detectMeeting(url: url, using: workspace).map { ($0, url) } }).first {
            return .init(url: url, original: original, isMeeting: true, calendarId: calendar.id)
        }
        else if let url = links.first {
            return .init(url: url, original: url, isMeeting: false, calendarId: calendar.id)
        }

        return nil
    }
}

private func detectLinks(_ texts: [String?]) -> [URL] {

    let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    return texts.compact().flatMap { text in
        detector
            .matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            .filter { text[Range($0.range, in: text)!].contains("://") }
            .compactMap(\.url)
    }
}

private func detectMeeting(url: URL?, using workspace: WorkspaceServiceProviding) -> URL? {

    guard
        let link = url?.absoluteString,
        let old_scheme = url?.scheme.map({ "\($0)://" }),
        let app = WorkspaceApp(for: link)
    else { return nil }

    switch app {

    case .zoom(let app_scheme) where workspace.supports(scheme: app_scheme):

        return URL(
            string: link
                .replacingOccurrences(of: old_scheme, with: app_scheme)
                .replacingOccurrences(of: "?", with: "&")
                .replacingOccurrences(of: "/j/", with: "/join?confno=")
        )

    case .teams(let app_scheme) where workspace.supports(scheme: app_scheme):

        return URL(string: link.replacingOccurrences(of: old_scheme, with: app_scheme))

    default:
        return url
    }
}

private enum WorkspaceApp {

    case zoom(String)
    case teams(String)
    case other

    init?(for link: String) {

        if link.contains("zoom.us/j") {
            self = .zoom("zoommtg://")
        }
        else if link.contains("teams.microsoft.com/l/meetup-join") {
            self = .teams("msteams://")
        }
        else if [
            "meet.google.com",
            "hangouts.google.com"
        ]
        .contains(where: link.contains) {
            self = .other
        }
        else {
            return nil
        }
    }
}
