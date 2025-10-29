//
//  Icons.swift
//  Calendr
//
//  Created by Paker on 19/06/2021.
//

import AppKit

enum Icons {

    enum Appearance {
        static let automatic = NSImage(systemName: "circle.lefthalf.fill")
        static let light = NSImage(systemName: "sun.max.fill")
        static let dark = NSImage(systemName: "moon.fill")
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
        static let create = NSImage(systemName: "plus")
    }

    enum CalendarPicker {
        static let nextEventEnabled = NSImage(systemName: "alarm")
        static let nextEventSilenced = NSImage(systemName: "moon.zzz")
        static let subscribed = NSImage(systemName: "wave.3.right")
    }

    enum Settings {
        static let general = NSImage(systemName: "gear")
        static let blacklist = NSImage(systemName: "nosign")
        static let calendars = NSImage(systemName: "calendar.badge.plus")
        static let keyboard = NSImage(systemName: "keyboard")
        static let appearance = NSImage(systemName: "paintbrush")
        static let about = NSImage(systemName: "book")
        static let tooltip = NSImage(systemName: "info.circle")
        static let length_small = NSImage(systemName: "character.textbox")
        static let length_big = NSImage(systemName: "textformat.abc")
        static let zoomIn = NSImage(systemName: "plus.magnifyingglass")
        static let zoomOut = NSImage(systemName: "minus.magnifyingglass")
        static let transparencyLow = NSImage(systemName: "cube.transparent")
        static let transparencyHigh = NSImage(systemName: "cube.transparent.fill")
        static let textSmall = NSImage(systemName: "textformat.size.smaller")
        static let textLarge = NSImage(systemName: "textformat.size.larger")
        static let prev = Calendar.prev
        static let next = Calendar.next
    }

    enum Event {
        static let birthday = NSImage(systemName: "gift")
        static let attachment = NSImage(systemName: "paperclip")
        static let link = NSImage(systemName: "link")
        static let video = NSImage(systemName: "video")
        static let video_fill = NSImage(systemName: "video.fill")
        static let skip = NSImage(systemName: "forward")
        static let recurrence = NSImage(systemName: "repeat")
    }

    enum Reminder {
        static let incomplete = NSImage(systemName: "circle")
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
        static let map = NSImage(systemName: "map.fill")
    }
}
