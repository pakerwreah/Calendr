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
  internal enum EventDetails {
    internal enum Participant {
      /// me
      internal static let me = Strings.tr("Localizable", "event_details.participant.me", fallback: "me")
      /// organizer
      internal static let organizer = Strings.tr("Localizable", "event_details.participant.organizer", fallback: "organizer")
    }
  }
  internal enum EventStatus {
    /// Accepted
    internal static let accepted = Strings.tr("Localizable", "event_status.accepted", fallback: "Accepted")
    /// Declined
    internal static let declined = Strings.tr("Localizable", "event_status.declined", fallback: "Declined")
    /// my status:
    internal static let label = Strings.tr("Localizable", "event_status.label", fallback: "my status:")
    /// Maybe
    internal static let maybe = Strings.tr("Localizable", "event_status.maybe", fallback: "Maybe")
    /// Pending
    internal static let pending = Strings.tr("Localizable", "event_status.pending", fallback: "Pending")
    internal enum Action {
      /// Accept
      internal static let accept = Strings.tr("Localizable", "event_status.action.accept", fallback: "Accept")
      /// Decline
      internal static let decline = Strings.tr("Localizable", "event_status.action.decline", fallback: "Decline")
      /// Maybe
      internal static let maybe = Strings.tr("Localizable", "event_status.action.maybe", fallback: "Maybe")
    }
  }
  internal enum Formatter {
    internal enum Date {
      /// All day
      internal static let allDay = Strings.tr("Localizable", "formatter.date.all_day", fallback: "All day")
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
  internal enum Reminder {
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
    /// Transparency
    internal static let transparency = Strings.tr("Localizable", "settings.transparency", fallback: "Transparency")
    internal enum Calendar {
      /// Preserve selected date on hide
      internal static let preserveSelectedDate = Strings.tr("Localizable", "settings.calendar.preserve_selected_date", fallback: "Preserve selected date on hide")
      /// Show declined events
      internal static let showDeclinedEvents = Strings.tr("Localizable", "settings.calendar.show_declined_events", fallback: "Show declined events")
      /// This only works if it is also enabled in the native Calendar app.
      internal static let showDeclinedEventsTooltip = Strings.tr("Localizable", "settings.calendar.show_declined_events_tooltip", fallback: "This only works if it is also enabled in the native Calendar app.")
      /// Show week numbers
      internal static let showWeekNumbers = Strings.tr("Localizable", "settings.calendar.show_week_numbers", fallback: "Show week numbers")
    }
    internal enum Events {
      /// Finished
      internal static let finished = Strings.tr("Localizable", "settings.events.finished", fallback: "Finished")
      internal enum Finished {
        /// Fade
        internal static let fade = Strings.tr("Localizable", "settings.events.finished.fade", fallback: "Fade")
        /// Hide
        internal static let hide = Strings.tr("Localizable", "settings.events.finished.hide", fallback: "Hide")
      }
    }
    internal enum MenuBar {
      /// Date format
      internal static let dateFormat = Strings.tr("Localizable", "settings.menu_bar.date_format", fallback: "Date format")
      /// Custom
      internal static let dateFormatCustom = Strings.tr("Localizable", "settings.menu_bar.date_format_custom", fallback: "Custom")
      /// Shorten if 'notch' is present
      internal static let nextEventDetectNotch = Strings.tr("Localizable", "settings.menu_bar.next_event_detect_notch", fallback: "Shorten if 'notch' is present")
      /// Show date
      internal static let showDate = Strings.tr("Localizable", "settings.menu_bar.show_date", fallback: "Show date")
      /// Show icon
      internal static let showIcon = Strings.tr("Localizable", "settings.menu_bar.show_icon", fallback: "Show icon")
      /// Show next event
      internal static let showNextEvent = Strings.tr("Localizable", "settings.menu_bar.show_next_event", fallback: "Show next event")
    }
    internal enum Tab {
      /// About
      internal static let about = Strings.tr("Localizable", "settings.tab.about", fallback: "About")
      /// Calendars
      internal static let calendars = Strings.tr("Localizable", "settings.tab.calendars", fallback: "Calendars")
      /// General
      internal static let general = Strings.tr("Localizable", "settings.tab.general", fallback: "General")
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
