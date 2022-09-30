//
//  Prefs+UserDefaults.swift
//  Calendr
//
//  Created by Paker on 30/09/22.
//

import Foundation

enum Prefs {
    static let enabledCalendars = "enabled_calendars"
    static let statusItemIconEnabled = "status_item_icon_enabled"
    static let statusItemDateEnabled = "status_item_date_enabled"
    static let statusItemDateStyle = "status_item_date_style"
    static let showEventStatusItem = "show_event_status_item"
    static let eventStatusItemLength = "event_status_item_length"
    static let eventStatusItemDetectNotch = "event_status_item_detect_notch"
    static let showWeekNumbers = "show_week_numbers"
    static let preserveSelectedDate = "preserve_selected_date"
    static let showDeclinedEvents = "show_declined_events"
    static let showPastEvents = "show_past_events"
    static let transparencyLevel = "transparency_level"
    static let calendarScaling = "calendar_scaling"
}

extension UserDefaults {

    @objc dynamic var enabledCalendars: [String]? {
        get { stringArray(forKey: Prefs.enabledCalendars) }
        set { set(newValue, forKey: Prefs.enabledCalendars) }
    }

    @objc dynamic var statusItemIconEnabled: Bool {
        get { bool(forKey: Prefs.statusItemIconEnabled) }
        set { set(newValue, forKey: Prefs.statusItemIconEnabled) }
    }

    @objc dynamic var statusItemDateEnabled: Bool {
        get { bool(forKey: Prefs.statusItemDateEnabled) }
        set { set(newValue, forKey: Prefs.statusItemDateEnabled) }
    }

    @objc dynamic var statusItemDateStyle: UInt {
        get { UInt(integer(forKey: Prefs.statusItemDateStyle)) }
        set { set(newValue, forKey: Prefs.statusItemDateStyle) }
    }

    @objc dynamic var showEventStatusItem: Bool {
        get { bool(forKey: Prefs.showEventStatusItem) }
        set { set(newValue, forKey: Prefs.showEventStatusItem) }
    }

    @objc dynamic var eventStatusItemLength: Int {
        get { integer(forKey: Prefs.eventStatusItemLength) }
        set { set(newValue, forKey: Prefs.eventStatusItemLength) }
    }

    @objc dynamic var eventStatusItemDetectNotch: Bool {
        get { bool(forKey: Prefs.eventStatusItemDetectNotch) }
        set { set(newValue, forKey: Prefs.eventStatusItemDetectNotch) }
    }

    @objc dynamic var showWeekNumbers: Bool {
        get { bool(forKey: Prefs.showWeekNumbers) }
        set { set(newValue, forKey: Prefs.showWeekNumbers) }
    }

    @objc dynamic var preserveSelectedDate: Bool {
        get { bool(forKey: Prefs.preserveSelectedDate) }
        set { set(newValue, forKey: Prefs.preserveSelectedDate) }
    }

    @objc dynamic var showDeclinedEvents: Bool {
        get { bool(forKey: Prefs.showDeclinedEvents) }
        set { set(newValue, forKey: Prefs.showDeclinedEvents) }
    }

    @objc dynamic var showPastEvents: Bool {
        get { bool(forKey: Prefs.showPastEvents) }
        set { set(newValue, forKey: Prefs.showPastEvents) }
    }

    @objc dynamic var transparencyLevel: Int {
        get { integer(forKey: Prefs.transparencyLevel) }
        set { set(newValue, forKey: Prefs.transparencyLevel) }
    }

    @objc dynamic var calendarScaling: Double {
        get { double(forKey: Prefs.calendarScaling) }
        set { set(newValue, forKey: Prefs.calendarScaling) }
    }
}
