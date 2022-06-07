// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {
  /// Quit
  internal static var quit: String { return Strings.tr("Localizable", "quit") }

  internal enum EventDetails {
    internal enum Participant {
      /// me
      internal static var me: String { return Strings.tr("Localizable", "event_details.participant.me") }
      /// organizer
      internal static var organizer: String { return Strings.tr("Localizable", "event_details.participant.organizer") }
    }
  }

  internal enum EventStatus {
    /// Accepted
    internal static var accepted: String { return Strings.tr("Localizable", "event_status.accepted") }
    /// Declined
    internal static var declined: String { return Strings.tr("Localizable", "event_status.declined") }
    /// my status:
    internal static var label: String { return Strings.tr("Localizable", "event_status.label") }
    /// Maybe
    internal static var maybe: String { return Strings.tr("Localizable", "event_status.maybe") }
    /// Pending
    internal static var pending: String { return Strings.tr("Localizable", "event_status.pending") }
    internal enum Action {
      /// Accept
      internal static var accept: String { return Strings.tr("Localizable", "event_status.action.accept") }
      /// Decline
      internal static var decline: String { return Strings.tr("Localizable", "event_status.action.decline") }
      /// Maybe
      internal static var maybe: String { return Strings.tr("Localizable", "event_status.action.maybe") }
    }
  }

  internal enum Formatter {
    internal enum Date {
      /// All day
      internal static var allDay: String { return Strings.tr("Localizable", "formatter.date.all_day") }
      /// Today
      internal static var today: String { return Strings.tr("Localizable", "formatter.date.today") }
      internal enum Relative {
        /// %@ ago
        internal static func ago(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.ago", String(describing: p1))
        }
        /// in %@
        internal static func `in`(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.in", String(describing: p1))
        }
        /// %@ left
        internal static func `left`(_ p1: Any) -> String {
          return Strings.tr("Localizable", "formatter.date.relative.left", String(describing: p1))
        }
      }
    }
  }

  internal enum Reminder {
    internal enum Options {
      /// Options
      internal static var button: String { return Strings.tr("Localizable", "reminder.options.button") }
      /// Complete
      internal static var complete: String { return Strings.tr("Localizable", "reminder.options.complete") }
      /// Remind %@
      internal static func remind(_ p1: Any) -> String {
        return Strings.tr("Localizable", "reminder.options.remind", String(describing: p1))
      }
    }
  }

  internal enum Settings {
    /// Calendar
    internal static var calendar: String { return Strings.tr("Localizable", "settings.calendar") }
    /// Events
    internal static var events: String { return Strings.tr("Localizable", "settings.events") }
    /// Menu Bar
    internal static var menuBar: String { return Strings.tr("Localizable", "settings.menu_bar") }
    /// Transparency
    internal static var transparency: String { return Strings.tr("Localizable", "settings.transparency") }
    internal enum Calendar {
      /// Preserve selected date on hide
      internal static var preserveSelectedDate: String { return Strings.tr("Localizable", "settings.calendar.preserve_selected_date") }
      /// Show declined events
      internal static var showDeclinedEvents: String { return Strings.tr("Localizable", "settings.calendar.show_declined_events") }
      /// Show week numbers
      internal static var showWeekNumbers: String { return Strings.tr("Localizable", "settings.calendar.show_week_numbers") }
    }
    internal enum Events {
      /// Finished
      internal static var finished: String { return Strings.tr("Localizable", "settings.events.finished") }
      internal enum Finished {
        /// Fade
        internal static var fade: String { return Strings.tr("Localizable", "settings.events.finished.fade") }
        /// Hide
        internal static var hide: String { return Strings.tr("Localizable", "settings.events.finished.hide") }
      }
    }
    internal enum MenuBar {
      /// Date format
      internal static var dateFormat: String { return Strings.tr("Localizable", "settings.menu_bar.date_format") }
      /// Shorten if 'notch' is present
      internal static var nextEventDetectNotch: String { return Strings.tr("Localizable", "settings.menu_bar.next_event_detect_notch") }
      /// Width
      internal static var nextEventLength: String { return Strings.tr("Localizable", "settings.menu_bar.next_event_length") }
      /// Show date
      internal static var showDate: String { return Strings.tr("Localizable", "settings.menu_bar.show_date") }
      /// Show icon
      internal static var showIcon: String { return Strings.tr("Localizable", "settings.menu_bar.show_icon") }
      /// Show next event
      internal static var showNextEvent: String { return Strings.tr("Localizable", "settings.menu_bar.show_next_event") }
      internal enum DateFormat {
        /// Configurable in System Preferences
        internal static var info: String { return Strings.tr("Localizable", "settings.menu_bar.date_format.info") }
      }
    }
    internal enum Tab {
      /// About
      internal static var about: String { return Strings.tr("Localizable", "settings.tab.about") }
      /// Calendars
      internal static var calendars: String { return Strings.tr("Localizable", "settings.tab.calendars") }
      /// General
      internal static var general: String { return Strings.tr("Localizable", "settings.tab.general") }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = lookupFunction(key, table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
