//
//  EventLink.swift
//  Calendr
//
//  Created by Paker on 04/06/22.
//

import Foundation

struct EventLink: Equatable {
    let url: URL
    let isMeeting: Bool
}

extension EventModel {

    func detectLink(using workspace: WorkspaceServiceProviding) -> EventLink? {

        let links = !type.isBirthday
            ? detectLinks([location, url?.absoluteString, notes])
            : []

        if let url = links.lazy.compactMap({ detectMeeting(url: $0, using: workspace) }).first {
            return .init(url: url, isMeeting: true)
        }
        else if let url = links.first {
            return .init(url: url, isMeeting: false)
        }

        return nil
    }
}

func detectLinks(_ texts: [String?]) -> [URL] {

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
