//
//  Icons.swift
//  Calendr
//
//  Created by Paker on 19/06/2021.
//

import AppKit

enum Icons {

    enum MenuBar {
        static let icon = NSImage(systemName: "calendar")
    }

    enum Calendar {
        static let prev = NSImage(systemName: "chevron.backward")
        static let reset = NSImage(systemName: "arrow.clockwise")
        static let next = NSImage(systemName: "chevron.forward")
        static let calendar = NSImage(systemName: "calendar")
        static let settings = NSImage(systemName: "ellipsis.circle")
    }

    enum Settings {
        static let general = NSImage(systemName: "house")
        static let calendars = NSImage(systemName: "list.bullet")
        static let about = NSImage(systemName: "book")
    }

    enum EventDetails {
        static let options = NSImage(systemName: "chevron.down")
    }
}
