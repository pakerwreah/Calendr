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
    }

    enum CalendarPicker {
        static let nextEventSelected = NSImage(systemName: "alarm")
        static let nextEventUnselected = NSImage(systemName: "moon.zzz")
    }

    enum Settings {
        static let general = NSImage(systemName: "gear")
        static let calendars = NSImage(systemName: "calendar.badge.plus")
        static let about = NSImage(systemName: "book")
        static let tooltip = NSImage(systemName: "info.circle")
        static let ruler = NSImage(systemName: "ruler")
        static let zoomIn = NSImage(systemName: "plus.magnifyingglass")
        static let zoomOut = NSImage(systemName: "minus.magnifyingglass")
    }

    enum Event {
        static let birthday = NSImage(systemName: "gift")
        static let reminder = NSImage(systemName: "bell.fill")
        static let link = NSImage(systemName: "link")
        static let video = NSImage(systemName: "video")
        static let video_fill = NSImage(systemName: "video.fill")
        static let open = NSImage(systemName: "square.and.arrow.up")
        static let skip = NSImage(systemName: "forward")
    }

    enum Reminder {
        static let open = Event.open
        static let complete = NSImage(systemName: "circle.inset.filled")
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
