//
//  Prefs+UserDefaults.swift
//  Calendr
//
//  Created by Paker on 30/09/22.
//

import Foundation

enum Prefs {
    // Menu Bar
    static let disabledCalendars = "disabled_calendars"
    static let silencedCalendars = "silenced_calendars"
    static let statusItemIconEnabled = "status_item_icon_enabled"
    static let statusItemIconStyle = "status_item_icon_style"
    static let statusItemDateEnabled = "status_item_date_enabled"
    static let statusItemDateStyle = "status_item_date_style"
    static let statusItemDateFormat = "status_item_date_format"
    static let statusItemBackgroundEnabled = "status_item_background_enabled"
    static let statusItemTextScaling = "status_item_text_scaling"

    // Next Event
    static let showEventStatusItem = "show_event_status_item"
    static let eventStatusItemCheckRange = "event_status_item_check_range"
    static let eventStatusItemFlashing = "event_status_item_flashing"
    static let eventStatusItemSound = "event_status_item_sound"
    static let eventStatusItemLength = "event_status_item_length"
    static let eventStatusItemDetectNotch = "event_status_item_detect_notch"
    static let eventStatusItemTextScaling = "event_status_item_text_scaling"

    // Calendar
    static let calendarScaling = "calendar_scaling"
    static let firstWeekday = "first_weekday"
    static let highlightedWeekdays = "highlighted_weekdays"
    static let showWeekNumbers = "show_week_numbers"
    static let showDeclinedEvents = "show_declined_events"
    static let preserveSelectedDate = "preserve_selected_date"
    static let dateHoverOption = "date_hover_option"
    static let calendarAppViewMode = "calendar_app_view_mode"
    static let calendarTextScaling = "calendar_text_scaling"

    // Event Details
    static let showMap = "show_map"
    static let showMapBlacklistRegex = "show_map_blacklist_regex"

    // Events
    static let showPastEvents = "show_past_events"
    static let showOverdueReminders = "show_overdue_reminders"
    static let showRecurrenceIndicator = "show_recurrence_indicator"
    static let forceLocalTimeZone = "force_local_time_zone"

    // Appearance
    static let appearanceMode = "appearance_mode"
    static let transparencyLevel = "transparency_level"
    static let textScaling = "text_scaling"

    // Misc
    static let lastCheckedVersion = "last_checked_version"
    static let updatedVersion = "updated_version"
    static let permissionSuppressed = "permission_suppressed"
    static let defaultBrowserPerCalendar = "default_browser_per_calendar"

    // Security Scope Bookmarks
    static let attachmentsBookmark = "attachments_folder_bookmark"

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
        Prefs.statusItemTextScaling: 1.2,

        // Next Event
        Prefs.showEventStatusItem: false,
        Prefs.eventStatusItemCheckRange: 6,
        Prefs.eventStatusItemFlashing: false,
        Prefs.eventStatusItemSound: false,
        Prefs.eventStatusItemTextScaling: 1.2,
        Prefs.eventStatusItemLength: 18,
        Prefs.eventStatusItemDetectNotch: false,

        // Calendar
        Prefs.calendarScaling: 1,
        Prefs.firstWeekday: calendar.firstWeekday,
        Prefs.highlightedWeekdays: [0, 6],
        Prefs.showWeekNumbers: false,
        Prefs.showDeclinedEvents: false,
        Prefs.preserveSelectedDate: false,
        Prefs.dateHoverOption: false,
        Prefs.calendarAppViewMode: CalendarViewMode.month.rawValue,
        Prefs.calendarTextScaling: 1,

        // Event Details
        Prefs.showMap: true,

        // Events
        Prefs.showPastEvents: true,
        Prefs.showOverdueReminders: true,
        Prefs.showRecurrenceIndicator: true,
        Prefs.forceLocalTimeZone: false,

        // Appearance
        Prefs.appearanceMode: 0,
        Prefs.transparencyLevel: 2,
        Prefs.textScaling: 1,

        // Misc
        Prefs.defaultBrowserPerCalendar: [:]
    ])
}

extension UserDefaults {

    // Menu Bar

    @objc dynamic var disabledCalendars: [String] {
        get { stringArray(forKey: Prefs.disabledCalendars) ?? [] }
        set { set(newValue, forKey: Prefs.disabledCalendars) }
    }

    @objc dynamic var silencedCalendars: [String] {
        get { stringArray(forKey: Prefs.silencedCalendars) ?? [] }
        set { set(newValue, forKey: Prefs.silencedCalendars) }
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

    @objc dynamic var statusItemTextScaling: Double {
        get { double(forKey: Prefs.statusItemTextScaling) }
        set { set(newValue, forKey: Prefs.statusItemTextScaling) }
    }

    // Next Event

    @objc dynamic var showEventStatusItem: Bool {
        get { bool(forKey: Prefs.showEventStatusItem) }
        set { set(newValue, forKey: Prefs.showEventStatusItem) }
    }

    @objc dynamic var eventStatusItemCheckRange: Int {
        get { integer(forKey: Prefs.eventStatusItemCheckRange) }
        set { set(newValue, forKey: Prefs.eventStatusItemCheckRange) }
    }

    @objc dynamic var eventStatusItemFlashing: Bool {
        get { bool(forKey: Prefs.eventStatusItemFlashing) }
        set { set(newValue, forKey: Prefs.eventStatusItemFlashing) }
    }

    @objc dynamic var eventStatusItemSound: Bool {
        get { bool(forKey: Prefs.eventStatusItemSound) }
        set { set(newValue, forKey: Prefs.eventStatusItemSound) }
    }

    @objc dynamic var eventStatusItemTextScaling: Double {
        get { double(forKey: Prefs.eventStatusItemTextScaling) }
        set { set(newValue, forKey: Prefs.eventStatusItemTextScaling) }
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

    @objc dynamic var dateHoverOption: Bool {
        get { bool(forKey: Prefs.dateHoverOption) }
        set { set(newValue, forKey: Prefs.dateHoverOption) }
    }

    @objc dynamic var calendarAppViewMode: String {
        get { string(forKey: Prefs.calendarAppViewMode) ?? "" }
        set { set(newValue, forKey: Prefs.calendarAppViewMode) }
    }

    @objc dynamic var calendarTextScaling: Double {
        get { double(forKey: Prefs.calendarTextScaling) }
        set { set(newValue, forKey: Prefs.calendarTextScaling) }
    }

    // Event Details

    @objc dynamic var showMap: Bool {
        get { bool(forKey: Prefs.showMap) }
        set { set(newValue, forKey: Prefs.showMap) }
    }

    @objc dynamic var showMapBlacklistRegex: String? {
        get { string(forKey: Prefs.showMapBlacklistRegex) }
        set { set(newValue, forKey: Prefs.showMapBlacklistRegex) }
    }

    // Events

    @objc dynamic var showPastEvents: Bool {
        get { bool(forKey: Prefs.showPastEvents) }
        set { set(newValue, forKey: Prefs.showPastEvents) }
    }

    @objc dynamic var showOverdueReminders: Bool {
        get { bool(forKey: Prefs.showOverdueReminders) }
        set { set(newValue, forKey: Prefs.showOverdueReminders) }
    }

    @objc dynamic var showRecurrenceIndicator: Bool {
        get { bool(forKey: Prefs.showRecurrenceIndicator) }
        set { set(newValue, forKey: Prefs.showRecurrenceIndicator) }
    }

    @objc dynamic var forceLocalTimeZone: Bool {
        get { bool(forKey: Prefs.forceLocalTimeZone) }
        set { set(newValue, forKey: Prefs.forceLocalTimeZone) }
    }

    // Appearance

    @objc dynamic var appearanceMode: Int {
        get { integer(forKey: Prefs.appearanceMode) }
        set { set(newValue, forKey: Prefs.appearanceMode) }
    }

    @objc dynamic var transparencyLevel: Int {
        get { integer(forKey: Prefs.transparencyLevel) }
        set { set(newValue, forKey: Prefs.transparencyLevel) }
    }

    @objc dynamic var textScaling: Double {
        get { double(forKey: Prefs.textScaling) }
        set { set(newValue, forKey: Prefs.textScaling) }
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

    @objc dynamic var defaultBrowserPerCalendar: [String: String] {
        get { dictionary(forKey: Prefs.defaultBrowserPerCalendar) as? [String: String] ?? [:] }
        set { set(newValue, forKey: Prefs.defaultBrowserPerCalendar) }
    }

    // Security Scope Bookmarks
    @objc dynamic var attachmentsBookmark: Data? {
        get { data(forKey: Prefs.attachmentsBookmark) }
        set { set(newValue, forKey: Prefs.attachmentsBookmark) }
    }
}
