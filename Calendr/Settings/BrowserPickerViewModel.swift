//
//  BrowserPickerViewModel.swift
//  Calendr
//
//  Created by Paker on 02/08/2026.
//

import AppKit
import RxSwift

enum BrowserPickerSource {
    case settings
    case event
}

class BrowserPickerViewModel {

    let options: [BrowserOption]
    let selectedIndex: Observable<Int>
    let selectedIndexObserver: AnyObserver<Int>
    let controlShowIcon: Observable<Bool>
    let controlShowImageOnly: Bool

    init(
        calendarId: String,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider,
        source: BrowserPickerSource
    ) {
        controlShowImageOnly = source == .event

        let defaultBrowserURL = workspace.urlForDefaultBrowserApplication()

        options = workspace.urlsForBrowsersApplications()
            .compactMap { url -> BrowserOption? in
                guard
                    url.lastPathComponent.hasSuffix(".app"),
                    url.deletingLastPathComponent().lastPathComponent == "Applications",
                    let res = try? url.resourceValues(forKeys: [.nameKey, .effectiveIconKey]),
                    let icon = res.effectiveIcon as? NSImage,
                    let name = res.name
                else {
                    return nil
                }
                return .init(
                    icon: icon,
                    name: String(name.dropLast(4)),
                    url: url,
                    isDefault: url == defaultBrowserURL
                )
            }
            .sorted {
                if $0.isDefault && !$1.isDefault {
                    return true // $0 is default, so it should come first
                }
                if !$0.isDefault && $1.isDefault {
                    return false // $1 is default, so it should come first
                }
                return $0.name < $1.name // Otherwise, sort by name
            }

        selectedIndex = localStorage.rx.observe(\.defaultBrowserPerCalendar)
            .map { [options] in
                let url = if let path = $0[calendarId], let pathUrl = URL(string: path) {
                    pathUrl
                } else {
                    defaultBrowserURL
                }
                return options.firstIndex { $0.url == url } ?? 0
            }

        selectedIndexObserver = localStorage.rx.observer(for: \.defaultBrowserPerCalendar)
            .mapObserver { [options] index in
                var mapping = localStorage.defaultBrowserPerCalendar
                if index > 0 {
                    mapping[calendarId] = options[index].url.absoluteString
                } else {
                    mapping.removeValue(forKey: calendarId)
                }
                return mapping
            }

        controlShowIcon = selectedIndex.map { source != .event || $0 > 0 }.take(until: \.isTrue, behavior: .inclusive)
    }
}
