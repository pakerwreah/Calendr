//
//  UITestCase+Queries.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

extension UITestCase {

    static let app = XCUIApplication()
    var app: XCUIApplication { Self.app }

    enum MenuBar {
        static var main: XCUIElement { app.statusItems[Accessibility.MenuBar.main].wait(.shortTimeout) }
        static var event: XCUIElement { app.statusItems[Accessibility.MenuBar.event] }
        static var reminder: XCUIElement { app.statusItems[Accessibility.MenuBar.reminder] }
    }

    enum Main {
        static var view: XCUIElement { app.otherElements[Accessibility.Main.view] }

        static var title: XCUIElement { view.staticTexts[Accessibility.Main.title] }
        static var prevBtn: XCUIElement { view.buttons[Accessibility.Main.prevBtn] }
        static var resetBtn: XCUIElement { view.buttons[Accessibility.Main.resetBtn] }
        static var nextBtn: XCUIElement { view.buttons[Accessibility.Main.nextBtn] }
        static var pinBtn: XCUIElement { view.checkBoxes[Accessibility.Main.pinBtn] }
        static var remindersBtn: XCUIElement { view.buttons[Accessibility.Main.remindersBtn] }
        static var calendarBtn: XCUIElement { view.buttons[Accessibility.Main.calendarBtn] }
        static var settingsBtn: XCUIElement { view.buttons[Accessibility.Main.settingsBtn] }
        static var searchInput: XCUIElement { view.searchFields.element }

        static func openSettings() {
            settingsBtn.click()
            settingsBtn.menuItem("Preferences").click()
        }
    }

    enum Calendar {
        static var view: XCUIElement { Main.view.otherElements[Accessibility.Calendar.view] }

        static var weekNumbers: [XCUIElement] { view.otherElements[Accessibility.Calendar.weekNumber].staticTexts.array }
        static var weekDays: [XCUIElement] { view.otherElements[Accessibility.Calendar.weekDay].staticTexts.array }
        static var dates: [XCUIElement] { view.otherElements[Accessibility.Calendar.date].staticTexts.array }

        static var today: XCUIElement { view.otherElements[Accessibility.Calendar.today].staticTexts.element }
        static var selected: XCUIElement { view.otherElements[Accessibility.Calendar.selected].staticTexts.element }
        static var hovered: XCUIElement { view.otherElements[Accessibility.Calendar.hovered].staticTexts.element }

        static var events: [XCUIElement] {
            view.otherElements.matching(identifier: Accessibility.Calendar.selected)
                .otherElements.matching(identifier: Accessibility.Calendar.event).array
        }
    }

    enum EventList {
        static var view: XCUIElement { Main.view.otherElements[Accessibility.EventList.view].wait(.shortTimeout) }
        static var events: [XCUIElement] { view.otherElements.matching(identifier: Accessibility.EventList.event).array }
    }

    enum EventDetails {
        static var view: XCUIElement { app.otherElements[Accessibility.EventDetails.view] }
    }

    enum ReminderDetails {
        static var view: XCUIElement { app.otherElements[Accessibility.ReminderDetails.view] }
    }

    enum CalendarPicker {
        static var view: XCUIElement { app.otherElements[Accessibility.CalendarPicker.view] }
    }

    enum Settings {
        static var window: XCUIElement { app.dialogs[Accessibility.Settings.window] }
        static var view: XCUIElement { app.otherElements[Accessibility.Settings.view] }
        static var tabs: [XCUIElement] { window.toolbars.buttons.array }

        enum Tab {
            private static func predicate(for label: String) -> NSPredicate { NSPredicate(format: "label = %@", label) }

            static var general: XCUIElement { window.toolbars.buttons.element(matching: predicate(for: "General")) }
            static var calendars: XCUIElement { window.toolbars.buttons.element(matching: predicate(for: "Calendars")) }
            static var about: XCUIElement { window.toolbars.buttons.element(matching: predicate(for: "About")) }
        }

        enum General {
            static var view: XCUIElement { Settings.view.otherElements[Accessibility.Settings.General.view] }
            static var dateFormatDropdown: XCUIElement { view.popUpButtons[Accessibility.Settings.General.dateFormatDropdown] }
            static var dateFormatInput: XCUIElement { view.textFields[Accessibility.Settings.General.dateFormatInput] }
        }

        enum Calendars {
            static var view: XCUIElement { Settings.view.otherElements[Accessibility.Settings.Calendars.view] }
        }

        enum About {
            static var view: XCUIElement { Settings.view.otherElements[Accessibility.Settings.About.view] }
            static var quitBtn: XCUIElement { view.descendants(matching: .button)[Accessibility.Settings.About.quitBtn] }
        }
    }
}

// MARK: - Helpers

extension TimeInterval {
    static let shortTimeout: Self = 0.1
    static let longTimeout: Self = 0.5
}

extension XCUIElement {

    var didAppear: Bool { waitForExistence(timeout: 1) && !frame.isEmpty }

    var text: String { value as! String }
    var isChecked: Bool { value as! Bool }

    var outside: XCUICoordinate { coordinate(withNormalizedOffset: .zero).withOffset(.init(dx: -500, dy: 500)) }

    var hasFocus: Bool { value(forKey: "hasKeyboardFocus") as? Bool ?? false }

    func replaceText(_ text: String) {

        guard let current = value as? String else { return }

        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)+text)
    }

    func wait(_ timeout: TimeInterval, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssert(waitForExistence(timeout: timeout), "Missing '\(self)' element", file: file, line: line)
        return self
    }

    func menuItem(_ title: String) -> XCUIElement {
        menuItems.element(matching: .title(title))
    }
}

extension XCUIElementQuery {

    var array: [XCUIElement] { allElementsBoundByAccessibilityElement }

    subscript(_ identifier: String) -> XCUIElement {

        element(matching: .predicate(for: identifier))
    }

    func matching(identifier: String) -> XCUIElementQuery {

        matching(.predicate(for: identifier))
    }
}

private extension NSPredicate {

    static func predicate(for identifier: String) -> Self {

        .init { (item, bindings) -> Bool in

            guard let item = item as? XCUIElementAttributes else { return false }

            return item.identifier.components(separatedBy: ",").contains(identifier)
        }
    }
}

extension NSPredicate {

    static func title(_ title: String) -> NSPredicate { .init(format: "title = %@", title) }
}
