// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {
  /// Localizable.strings
  ///   Calendr
  /// 
  ///   Created by Paker on 20/02/2021.
  internal static let quit = Strings.tr("Localizable", "quit", fallback: "Quit")
  /// Search
  internal static let search = Strings.tr("Localizable", "search", fallback: "Search")
  internal enum AccessRequired {
    /// Calendar pending 'Full access' authorization
    internal static let calendars = Strings.tr("Localizable", "access_required.calendars", fallback: "Calendar pending 'Full access' authorization")
    /// Cancel
    internal static let cancel = Strings.tr("Localizable", "access_required.cancel", fallback: "Cancel")
    /// Open Settings
    internal static let openSettings = Strings.tr("Localizable", "access_required.open_settings", fallback: "Open Settings")
    /// Reminders pending authorization
    internal static let reminders = Strings.tr("Localizable", "access_required.reminders", fallback: "Reminders pending authorization")
  }
  internal enum Attachments {
    internal enum Open {
      /// Authorize access to attachments
      internal static let authorize = Strings.tr("Localizable", "attachments.open.authorize", fallback: "Authorize access to attachments")
      /// Calendr needs permission to access your attachments
      internal static let message = Strings.tr("Localizable", "attachments.open.message", fallback: "Calendr needs permission to access your attachments")
    }
  }
  internal enum AutoUpdate {
    /// Check for updates
    internal static let checkForUpdates = Strings.tr("Localizable", "auto_update.check_for_updates", fallback: "Check for updates")
    /// Downloading version %@
    internal static func downloading(_ p1: Any) -> String {
      return Strings.tr("Localizable", "auto_update.downloading", String(describing: p1), fallback: "Downloading version %@")
    }
    /// Fetching releases
    internal static let fetchingReleases = Strings.tr("Localizable", "auto_update.fetching_releases", fallback: "Fetching releases")
    /// Install
    internal static let install = Strings.tr("Localizable", "auto_update.install", fallback: "Install")
    /// New version available: %@
    internal static func newVersion(_ p1: Any) -> String {
      return Strings.tr("Localizable", "auto_update.new_version", String(describing: p1), fallback: "New version available: %@")
    }
    /// Updated to version %@
    internal static func updatedTo(_ p1: Any) -> String {
      return Strings.tr("Localizable", "auto_update.updated_to", String(describing: p1), fallback: "Updated to version %@")
    }
    internal enum Replace {
      /// Confirm the app location so we have permission to replace it
      internal static let message = Strings.tr("Localizable", "auto_update.replace.message", fallback: "Confirm the app location so we have permission to replace it")
    }
  }
  internal enum Calendars {
    internal enum Source {
      /// Others
      internal static let others = Strings.tr("Localizable", "calendars.source.others", fallback: "Others")
    }
  }
  internal enum Event {
    /// All day
    internal static let allDay = Strings.tr("Localizable", "event.all_day", fallback: "All day")
    internal enum Action {
      /// Accept
      internal static let accept = Strings.tr("Localizable", "event.action.accept", fallback: "Accept")
      /// Decline
      internal static let decline = Strings.tr("Localizable", "event.action.decline", fallback: "Decline")
      /// Join
      internal static let join = Strings.tr("Localizable", "event.action.join", fallback: "Join")
      /// Maybe
      internal static let maybe = Strings.tr("Localizable", "event.action.maybe", fallback: "Maybe")
      /// Open
      internal static let `open` = Strings.tr("Localizable", "event.action.open", fallback: "Open")
      /// Skip
      internal static let skip = Strings.tr("Localizable", "event.action.skip", fallback: "Skip")
    }
    internal enum Details {
      internal enum Participant {
        /// me
        internal static let me = Strings.tr("Localizable", "event.details.participant.me", fallback: "me")
        /// organizer
        internal static let organizer = Strings.tr("Localizable", "event.details.participant.organizer", fallback: "organizer")
      }
    }
    internal enum Status {
      /// Accepted
      internal static let accepted = Strings.tr("Localizable", "event.status.accepted", fallback: "Accepted")
      /// Declined
      internal static let declined = Strings.tr("Localizable", "event.status.declined", fallback: "Declined")
      /// Maybe
      internal static let maybe = Strings.tr("Localizable", "event.status.maybe", fallback: "Maybe")
      /// Pending
      internal static let pending = Strings.tr("Localizable", "event.status.pending", fallback: "Pending")
    }
  }
  internal enum Formatter {
    internal enum Date {
      /// Today
      internal static let today = Strings.tr("Localizable", "formatter.date.today", fallback: "Today")
      internal enum Relative {
        /// %@ ago
        internal static func ago(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.ago", String(describing: p1), fallback: "%@ ago")
        }
        /// in %@
        internal static func `in`(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.in", String(describing: p1), fallback: "in %@")
        }
        /// %@ left
        internal static func `left`(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.left", String(describing: p1), fallback: "%@ left")
        }
      }
    }
  }
  internal enum MapBlackList {
    /// Hide map if location contains any of these words
    internal static let headline = Strings.tr("Localizable", "map_black_list.headline", fallback: "Hide map if location contains any of these words")
  }
  internal enum Reminder {
    internal enum Editor {
      /// New Reminder
      internal static let headline = Strings.tr("Localizable", "reminder.editor.headline", fallback: "New Reminder")
      /// Save
      internal static let save = Strings.tr("Localizable", "reminder.editor.save", fallback: "Save")
      /// Title
      internal static let title = Strings.tr("Localizable", "reminder.editor.title", fallback: "Title")
      internal enum Confirm {
        /// Continue editing
        internal static let `continue` = Strings.tr("Localizable", "reminder.editor.confirm.continue", fallback: "Continue editing")
        /// Discard all changes
        internal static let discard = Strings.tr("Localizable", "reminder.editor.confirm.discard", fallback: "Discard all changes")
      }
    }
    internal enum Options {
      /// Options
      internal static let button = Strings.tr("Localizable", "reminder.options.button", fallback: "Options")
      /// Complete
      internal static let complete = Strings.tr("Localizable", "reminder.options.complete", fallback: "Complete")
      /// Remind %@
      internal static func remind(_ p1: Any) -> String {
        return Strings.tr("Localizable", "reminder.options.remind", String(describing: p1), fallback: "Remind %@")
      }
    }
    internal enum Status {
      /// Overdue
      internal static let overdue = Strings.tr("Localizable", "reminder.status.overdue", fallback: "Overdue")
    }
  }
  internal enum Settings {
    /// Calendar
    internal static let calendar = Strings.tr("Localizable", "settings.calendar", fallback: "Calendar")
    /// Events
    internal static let events = Strings.tr("Localizable", "settings.events", fallback: "Events")
    /// Menu Bar
    internal static let menuBar = Strings.tr("Localizable", "settings.menu_bar", fallback: "Menu Bar")
    /// Next Event
    internal static let nextEvent = Strings.tr("Localizable", "settings.next_event", fallback: "Next Event")
    /// Preferences
    internal static let title = Strings.tr("Localizable", "settings.title", fallback: "Preferences")
    internal enum Appearance {
      /// Accessibility
      internal static let accessibility = Strings.tr("Localizable", "settings.appearance.accessibility", fallback: "Accessibility")
      /// Transparency
      internal static let transparency = Strings.tr("Localizable", "settings.appearance.transparency", fallback: "Transparency")
    }
    internal enum Calendar {
      /// Calendar app view
      internal static let calendarAppViewMode = Strings.tr("Localizable", "settings.calendar.calendar_app_view_mode", fallback: "Calendar app view")
      /// Hold ⌥ to peek at hovered dates
      internal static let dateHoverOption = Strings.tr("Localizable", "settings.calendar.date_hover_option", fallback: "Hold ⌥ to peek at hovered dates")
      /// Default calendar app
      internal static let defaultCalendarApp = Strings.tr("Localizable", "settings.calendar.default_calendar_app", fallback: "Default calendar app")
      /// Event dots
      internal static let eventDots = Strings.tr("Localizable", "settings.calendar.event_dots", fallback: "Event dots")
      /// Preserve selected date on hide
      internal static let preserveSelectedDate = Strings.tr("Localizable", "settings.calendar.preserve_selected_date", fallback: "Preserve selected date on hide")
      /// Show declined events
      internal static let showDeclinedEvents = Strings.tr("Localizable", "settings.calendar.show_declined_events", fallback: "Show declined events")
      /// This only works if it is also enabled in the native Calendar app.
      internal static let showDeclinedEventsTooltip = Strings.tr("Localizable", "settings.calendar.show_declined_events_tooltip", fallback: "This only works if it is also enabled in the native Calendar app.")
      /// Show week numbers
      internal static let showWeekNumbers = Strings.tr("Localizable", "settings.calendar.show_week_numbers", fallback: "Show week numbers")
      /// Visible weeks
      internal static let weekCount = Strings.tr("Localizable", "settings.calendar.week_count", fallback: "Visible weeks")
      internal enum EventDots {
        /// multiple
        internal static let multiple = Strings.tr("Localizable", "settings.calendar.event_dots.multiple", fallback: "multiple")
        /// none
        internal static let `none` = Strings.tr("Localizable", "settings.calendar.event_dots.none", fallback: "none")
        /// highlighted
        internal static let singleHighlighted = Strings.tr("Localizable", "settings.calendar.event_dots.single_highlighted", fallback: "highlighted")
        /// neutral
        internal static let singleNeutral = Strings.tr("Localizable", "settings.calendar.event_dots.single_neutral", fallback: "neutral")
      }
    }
    internal enum Events {
      /// Show all events in local time zone
      internal static let forceLocalTimeZone = Strings.tr("Localizable", "settings.events.force_local_time_zone", fallback: "Show all events in local time zone")
      /// Show all-day events details
      internal static let showAllDayDetails = Strings.tr("Localizable", "settings.events.show_all_day_details", fallback: "Show all-day events details")
      /// Show finished events
      internal static let showFinishedEvents = Strings.tr("Localizable", "settings.events.show_finished_events", fallback: "Show finished events")
      /// Show map and weather
      internal static let showMap = Strings.tr("Localizable", "settings.events.show_map", fallback: "Show map and weather")
      /// Show overdue reminders
      internal static let showOverdueReminders = Strings.tr("Localizable", "settings.events.show_overdue_reminders", fallback: "Show overdue reminders")
      /// Show recurrence indicator
      internal static let showRecurrenceIndicator = Strings.tr("Localizable", "settings.events.show_recurrence_indicator", fallback: "Show recurrence indicator")
    }
    internal enum Keyboard {
      internal enum GlobalShortcuts {
        /// Open calendar
        internal static let openCalendar = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.open_calendar", fallback: "Open calendar")
        /// Open next event
        internal static let openNextEvent = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.open_next_event", fallback: "Open next event")
        /// Next event options
        internal static let openNextEventOptions = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.open_next_event_options", fallback: "Next event options")
        /// Open next reminder
        internal static let openNextReminder = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.open_next_reminder", fallback: "Open next reminder")
        /// Next reminder options
        internal static let openNextReminderOptions = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.open_next_reminder_options", fallback: "Next reminder options")
        /// Global shortcuts
        internal static let title = Strings.tr("Localizable", "settings.keyboard.global_shortcuts.title", fallback: "Global shortcuts")
      }
      internal enum LocalShortcuts {
        /// Current date
        internal static let currDate = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.curr_date", fallback: "Current date")
        /// Next date
        internal static let nextDate = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.next_date", fallback: "Next date")
        /// Next month
        internal static let nextMonth = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.next_month", fallback: "Next month")
        /// Next week
        internal static let nextWeek = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.next_week", fallback: "Next week")
        /// Open selected date
        internal static let openDate = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.open_date", fallback: "Open selected date")
        /// Pin calendar
        internal static let pinCalendar = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.pin_calendar", fallback: "Pin calendar")
        /// Previous date
        internal static let prevDate = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.prev_date", fallback: "Previous date")
        /// Previous month
        internal static let prevMonth = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.prev_month", fallback: "Previous month")
        /// Previous week
        internal static let prevWeek = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.prev_week", fallback: "Previous week")
        /// Local shortcuts
        internal static let title = Strings.tr("Localizable", "settings.keyboard.local_shortcuts.title", fallback: "Local shortcuts")
      }
    }
    internal enum MenuBar {
      /// Launch at login
      internal static let autoLaunch = Strings.tr("Localizable", "settings.menu_bar.auto_launch", fallback: "Launch at login")
      /// Custom
      internal static let dateFormatCustom = Strings.tr("Localizable", "settings.menu_bar.date_format_custom", fallback: "Custom")
      /// Open on mouse hover
      internal static let openOnHover = Strings.tr("Localizable", "settings.menu_bar.open_on_hover", fallback: "Open on mouse hover")
      /// Show opaque background
      internal static let showBackground = Strings.tr("Localizable", "settings.menu_bar.show_background", fallback: "Show opaque background")
      /// Show date
      internal static let showDate = Strings.tr("Localizable", "settings.menu_bar.show_date", fallback: "Show date")
      /// Show icon
      internal static let showIcon = Strings.tr("Localizable", "settings.menu_bar.show_icon", fallback: "Show icon")
    }
    internal enum NextEvent {
      /// Shorten if 'notch' is present
      internal static let detectNotch = Strings.tr("Localizable", "settings.next_event.detect_notch", fallback: "Shorten if 'notch' is present")
      /// Grab attention when event is close
      internal static let grabAttention = Strings.tr("Localizable", "settings.next_event.grab_attention", fallback: "Grab attention when event is close")
      /// Show next event
      internal static let showNextEvent = Strings.tr("Localizable", "settings.next_event.show_next_event", fallback: "Show next event")
      internal enum GrabAttention {
        /// Flashing
        internal static let flashing = Strings.tr("Localizable", "settings.next_event.grab_attention.flashing", fallback: "Flashing")
        /// Play sound
        internal static let sound = Strings.tr("Localizable", "settings.next_event.grab_attention.sound", fallback: "Play sound")
      }
    }
    internal enum Tab {
      /// About
      internal static let about = Strings.tr("Localizable", "settings.tab.about", fallback: "About")
      /// Appearance
      internal static let appearance = Strings.tr("Localizable", "settings.tab.appearance", fallback: "Appearance")
      /// Calendars
      internal static let calendars = Strings.tr("Localizable", "settings.tab.calendars", fallback: "Calendars")
      /// General
      internal static let general = Strings.tr("Localizable", "settings.tab.general", fallback: "General")
      /// Shortcuts
      internal static let keyboard = Strings.tr("Localizable", "settings.tab.keyboard", fallback: "Shortcuts")
    }
  }
  internal enum Tooltips {
    internal enum Navigation {
      /// Next month
      internal static let nextMonth = Strings.tr("Localizable", "tooltips.navigation.next_month", fallback: "Next month")
      /// Previous month
      internal static let prevMonth = Strings.tr("Localizable", "tooltips.navigation.prev_month", fallback: "Previous month")
      /// Today
      internal static let today = Strings.tr("Localizable", "tooltips.navigation.today", fallback: "Today")
    }
    internal enum Toolbar {
      /// Create
      internal static let create = Strings.tr("Localizable", "tooltips.toolbar.create", fallback: "Create")
      /// Open Calendar
      internal static let openCalendar = Strings.tr("Localizable", "tooltips.toolbar.open_calendar", fallback: "Open Calendar")
      /// Open menu
      internal static let openMenu = Strings.tr("Localizable", "tooltips.toolbar.open_menu", fallback: "Open menu")
      /// Open Reminders
      internal static let openReminders = Strings.tr("Localizable", "tooltips.toolbar.open_reminders", fallback: "Open Reminders")
      /// Stay open
      internal static let stayOpen = Strings.tr("Localizable", "tooltips.toolbar.stay_open", fallback: "Stay open")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
