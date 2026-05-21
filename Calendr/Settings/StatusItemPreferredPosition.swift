//
//  StatusItemPreferredPosition.swift
//  Calendr
//
//  Created by Paker on 21/05/2026.
//

enum StatusItemPreferredPositionState {
    case visible
    case saved
}

func statusItemPreferredPositionKey(_ name: String, _ state: StatusItemPreferredPositionState) -> String {
    let key = "\(Prefs.statusItemPreferredPosition) \(name)"
    return switch state {
        case .visible: key
        case .saved: "saved \(key)"
    }
}

func setInitialStatusItemPositions(in localStorage: LocalStorageProvider) {
    let names = [
        StatusItemName.main,
        StatusItemName.event,
        StatusItemName.reminder
    ]

    for name in names {
        let visibleKey = statusItemPreferredPositionKey(name, .visible)
        let savedKey = statusItemPreferredPositionKey(name, .saved)

        let visiblePosition = localStorage.integer(forKey: visibleKey)
        let savedPosition = localStorage.integer(forKey: savedKey)

        if savedPosition == 0 {
            let position = visiblePosition > 0 ? visiblePosition : 100
            localStorage.set(position, forKey: visibleKey)
            localStorage.set(position, forKey: savedKey)
        }
    }
}

func restoreStatusItemPreferredPosition(_ name: String, in localStorage: LocalStorageProvider) {
    let key = statusItemPreferredPositionKey(name, .visible)
    let savedKey = statusItemPreferredPositionKey(name, .saved)
    let savedPosition = localStorage.integer(forKey: savedKey)

    if savedPosition > 0 {
        localStorage.set(savedPosition, forKey: key)
    }
}
