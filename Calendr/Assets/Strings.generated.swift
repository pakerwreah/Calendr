// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum Strings {

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
      /// Show date
      internal static var showDate: String { return Strings.tr("Localizable", "settings.menu_bar.show_date") }
      /// Show icon
      internal static var showIcon: String { return Strings.tr("Localizable", "settings.menu_bar.show_icon") }
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
