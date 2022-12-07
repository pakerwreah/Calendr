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
        static let reset = NSImage(systemName: "circle")
        static let next = NSImage(systemName: "chevron.forward")
        static let reminders = NSImage(systemName: "list.bullet")
        static let calendar = NSImage(systemName: "calendar")
        static let settings = NSImage(systemName: "ellipsis.circle")
        static let pinned = NSImage(systemName: "pin.fill")
        static let unpinned = NSImage(systemName: "pin")
        static let scalingMinus = NSImage(systemName: "minus.magnifyingglass")
        static let scalingPlus = NSImage(systemName: "plus.magnifyingglass")
    }

    enum Settings {
        static let general = NSImage(systemName: "gear")
        static let calendars = NSImage(systemName: "calendar.badge.plus")
        static let about = NSImage(systemName: "book")
        static let tooltip = NSImage(systemName: "info.circle")
    }

    enum Event {
        static let birthday = NSImage(systemName: "gift")
        static let reminder = NSImage(systemName: "bell.fill")
        static let link = NSImage(systemName: "link")
        static let video = NSImage(systemName: "video")
        static let video_fill = NSImage(systemName: "video.fill")
    }

    enum EventStatus {
        static let accepted = NSImage(systemName: "checkmark.circle")
        static let maybe = NSImage(systemName: "questionmark.circle")
        static let declined = NSImage(systemName: "x.circle")
        static let pending = NSImage(systemName: "questionmark.circle")
    }

    enum EventDetails {
        static let optionsArrow = NSImage(systemName: "chevron.down")
    }
}
