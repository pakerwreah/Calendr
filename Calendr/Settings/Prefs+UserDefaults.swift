//
//  Prefs+UserDefaults.swift
//  Calendr
//
//  Created by Paker on 30/09/22.
//

import Foundation

enum Prefs {
    // Menu Bar
    static let enabledCalendars = "enabled_calendars"
    static let nextEventCalendars = "next_event_calendars"
    static let statusItemIconEnabled = "status_item_icon_enabled"
    static let statusItemIconStyle = "status_item_icon_style"
    static let statusItemDateEnabled = "status_item_date_enabled"
    static let statusItemDateStyle = "status_item_date_style"
    static let statusItemDateFormat = "status_item_date_format"
    static let statusItemBackgroundEnabled = "status_item_background_enabled"

    // Next Event
    static let showEventStatusItem = "show_event_status_item"
    static let eventStatusItemFontSize = "event_status_item_font_size"
    static let eventStatusItemCheckRange = "event_status_item_check_range"
    static let eventStatusItemLength = "event_status_item_length"
    static let eventStatusItemDetectNotch = "event_status_item_detect_notch"

    // Calendar
    static let calendarScaling = "calendar_scaling"
    static let firstWeekday = "first_weekday"
    static let highlightedWeekdays = "highlighted_weekdays"
    static let showWeekNumbers = "show_week_numbers"
    static let showDeclinedEvents = "show_declined_events"
    static let preserveSelectedDate = "preserve_selected_date"

    // Event Details
    static let showMap = "show_map"

    // Events
    static let showPastEvents = "show_past_events"

    // Appearance
    static let transparencyLevel = "transparency_level"
    static let textScaling = "text_scaling"
    static let calendarTextScaling = "calendar_text_scaling"

    // Misc
    static let lastCheckedVersion = "last_checked_version"
    static let updatedVersion = "updated_version"
    static let permissionSuppressed = "permission_suppressed"

    // System
    static let statusItemPreferredPosition = "NSStatusItem Preferred Position"
}

func registerDefaultPrefs(in userDefaults: UserDefaults, calendar: Calendar = .current) {

    userDefaults.register(defaults: [
        // Menu Bar
        Prefs.statusItemIconEnabled: true,
        Prefs.statusItemIconStyle: StatusItemIconStyle.calendar.rawValue,
        Prefs.statusItemDateEnabled: true,
        Prefs.statusItemDateStyle: StatusItemDateStyle.short.rawValue,
        Prefs.statusItemDateFormat: AppConstants.defaultCustomDateFormat,
        Prefs.statusItemBackgroundEnabled: false,

        // Next Event
        Prefs.showEventStatusItem: false,
        Prefs.eventStatusItemFontSize: 12,
        Prefs.eventStatusItemCheckRange: 6,
        Prefs.eventStatusItemLength: 18,
        Prefs.eventStatusItemDetectNotch: false,

        // Calendar
        Prefs.calendarScaling: 1,
        Prefs.firstWeekday: calendar.firstWeekday,
        Prefs.highlightedWeekdays: [0, 6],
        Prefs.showWeekNumbers: false,
        Prefs.showDeclinedEvents: false,
        Prefs.preserveSelectedDate: false,

        // Event Details
        Prefs.showMap: true,

        // Events
        Prefs.showPastEvents: true,

        // Appearance
        Prefs.transparencyLevel: 2,
        Prefs.textScaling: 1,
        Prefs.calendarTextScaling: 1
    ])
}

extension UserDefaults {

    // Menu Bar

    @objc dynamic var enabledCalendars: [String]? {
        get { stringArray(forKey: Prefs.enabledCalendars) }
        set { set(newValue, forKey: Prefs.enabledCalendars) }
    }

    @objc dynamic var nextEventCalendars: [String]? {
        get { stringArray(forKey: Prefs.nextEventCalendars) }
        set { set(newValue, forKey: Prefs.nextEventCalendars) }
    }

    @objc dynamic var statusItemIconEnabled: Bool {
        get { bool(forKey: Prefs.statusItemIconEnabled) }
        set { set(newValue, forKey: Prefs.statusItemIconEnabled) }
    }

    @objc dynamic var statusItemIconStyle: String {
        get { string(forKey: Prefs.statusItemIconStyle) ?? "" }
        set { set(newValue, forKey: Prefs.statusItemIconStyle) }
    }

    @objc dynamic var statusItemDateEnabled: Bool {
        get { bool(forKey: Prefs.statusItemDateEnabled) }
        set { set(newValue, forKey: Prefs.statusItemDateEnabled) }
    }

    @objc dynamic var statusItemDateStyle: UInt {
        get { UInt(integer(forKey: Prefs.statusItemDateStyle)) }
        set { set(newValue, forKey: Prefs.statusItemDateStyle) }
    }

    @objc dynamic var statusItemDateFormat: String {
        get { string(forKey: Prefs.statusItemDateFormat) ?? "" }
        set { set(newValue, forKey: Prefs.statusItemDateFormat) }
    }

    @objc dynamic var statusItemBackgroundEnabled: Bool {
        get { bool(forKey: Prefs.statusItemBackgroundEnabled) }
        set { set(newValue, forKey: Prefs.statusItemBackgroundEnabled) }
    }

    // Next Event

    @objc dynamic var showEventStatusItem: Bool {
        get { bool(forKey: Prefs.showEventStatusItem) }
        set { set(newValue, forKey: Prefs.showEventStatusItem) }
    }

    @objc dynamic var eventStatusItemFontSize: Float {
        get { float(forKey: Prefs.eventStatusItemFontSize) }
        set { set(newValue, forKey: Prefs.eventStatusItemFontSize) }
    }

    @objc dynamic var eventStatusItemCheckRange: Int {
        get { integer(forKey: Prefs.eventStatusItemCheckRange) }
        set { set(newValue, forKey: Prefs.eventStatusItemCheckRange) }
    }

    @objc dynamic var eventStatusItemLength: Int {
        get { integer(forKey: Prefs.eventStatusItemLength) }
        set { set(newValue, forKey: Prefs.eventStatusItemLength) }
    }

    @objc dynamic var eventStatusItemDetectNotch: Bool {
        get { bool(forKey: Prefs.eventStatusItemDetectNotch) }
        set { set(newValue, forKey: Prefs.eventStatusItemDetectNotch) }
    }

    // Calendar

    @objc dynamic var calendarScaling: Double {
        get { double(forKey: Prefs.calendarScaling) }
        set { set(newValue, forKey: Prefs.calendarScaling) }
    }

    @objc dynamic var firstWeekday: Int {
        get { integer(forKey: Prefs.firstWeekday) }
        set { set(newValue, forKey: Prefs.firstWeekday) }
    }

    @objc dynamic var highlightedWeekdays: [Int] {
        get { array(forKey: Prefs.highlightedWeekdays) as? [Int] ?? []  }
        set { set(newValue, forKey: Prefs.highlightedWeekdays) }
    }

    @objc dynamic var showWeekNumbers: Bool {
        get { bool(forKey: Prefs.showWeekNumbers) }
        set { set(newValue, forKey: Prefs.showWeekNumbers) }
    }

    @objc dynamic var showDeclinedEvents: Bool {
        get { bool(forKey: Prefs.showDeclinedEvents) }
        set { set(newValue, forKey: Prefs.showDeclinedEvents) }
    }

    @objc dynamic var preserveSelectedDate: Bool {
        get { bool(forKey: Prefs.preserveSelectedDate) }
        set { set(newValue, forKey: Prefs.preserveSelectedDate) }
    }

    // Event Details

    @objc dynamic var showMap: Bool {
        get { bool(forKey: Prefs.showMap) }
        set { set(newValue, forKey: Prefs.showMap) }
    }

    // Events

    @objc dynamic var showPastEvents: Bool {
        get { bool(forKey: Prefs.showPastEvents) }
        set { set(newValue, forKey: Prefs.showPastEvents) }
    }

    // Appearance

    @objc dynamic var transparencyLevel: Int {
        get { integer(forKey: Prefs.transparencyLevel) }
        set { set(newValue, forKey: Prefs.transparencyLevel) }
    }

    @objc dynamic var textScaling: Double {
        get { double(forKey: Prefs.textScaling) }
        set { set(newValue, forKey: Prefs.textScaling) }
    }
    
    @objc dynamic var calendarTextScaling: Double {
        get { double(forKey: Prefs.calendarTextScaling) }
        set { set(newValue, forKey: Prefs.calendarTextScaling) }
    }

    // Misc

    @objc dynamic var lastCheckedVersion: String? {
        get { string(forKey: Prefs.lastCheckedVersion) }
        set { set(newValue, forKey: Prefs.lastCheckedVersion) }
    }

    @objc dynamic var updatedVersion: String? {
        get { string(forKey: Prefs.updatedVersion) }
        set { set(newValue, forKey: Prefs.updatedVersion) }
    }

    @objc dynamic var permissionSuppressed: [String] {
        get { array(forKey: Prefs.permissionSuppressed) as? [String] ?? [] }
        set { set(newValue, forKey: Prefs.permissionSuppressed) }
    }
}
