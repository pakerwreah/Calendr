//
//  WorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace

protocol WorkspaceServiceProviding {

    func urlForApplication(toOpen url: URL) -> URL?
    func supports(scheme: String) -> Bool
    func open(_ url: URL)
}

class WorkspaceServiceProvider: WorkspaceServiceProviding {

    func urlForApplication(toOpen url: URL) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: url)
    }

    func supports(scheme: String) -> Bool {
        URL(string: scheme).map(urlForApplication(toOpen:)) != nil
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

extension WorkspaceServiceProviding {

    func detectLinks(_ texts: [String?]) -> [URL] {

        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        return texts.compact().flatMap { text in
            detector
                .matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
                .filter { text[Range($0.range, in: text)!].contains("://") }
                .compactMap(\.url)
        }
    }

    func detectMeeting(_ url: URL?) -> URL? {

        guard
            let link = url?.absoluteString,
            let old_scheme = url?.scheme.map({ "\($0)://" }),
            let app = WorkspaceApp(for: link)
        else { return nil }

        switch app {

        case .zoom(let app_scheme) where supports(scheme: app_scheme):

            return URL(
                string: link
                    .replacingOccurrences(of: old_scheme, with: app_scheme)
                    .replacingOccurrences(of: "?", with: "&")
                    .replacingOccurrences(of: "/j/", with: "/join?confno=")
            )

        case .teams(let app_scheme) where supports(scheme: app_scheme):

            return URL(string: link.replacingOccurrences(of: old_scheme, with: app_scheme))

        default:
            return url
        }
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
