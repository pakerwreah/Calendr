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

    enum Main {
        static var view: XCUIElement { app.otherElements[Accessibility.Main.view] }

        static var title: XCUIElement { view.staticTexts[Accessibility.Main.title] }
        static var prevBtn: XCUIElement { view.buttons[Accessibility.Main.prevBtn] }
        static var resetBtn: XCUIElement { view.buttons[Accessibility.Main.resetBtn] }
        static var nextBtn: XCUIElement { view.buttons[Accessibility.Main.nextBtn] }
        static var pinBtn: XCUIElement { view.checkBoxes[Accessibility.Main.pinBtn] }
        static var calendarBtn: XCUIElement { view.buttons[Accessibility.Main.calendarBtn] }
        static var settingsBtn: XCUIElement { view.buttons[Accessibility.Main.settingsBtn] }
    }

    enum MenuBar {
        static var main: XCUIElement { app.statusItems[Accessibility.MenuBar.main] }
        static var event: XCUIElement { app.statusItems[Accessibility.MenuBar.event] }
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

    enum EventDetails {
        static var view: XCUIElement { app.otherElements[Accessibility.EventDetails.view] }
    }
}

// MARK: - Helpers

extension XCUIElement {

    var didAppear: Bool { exists && !frame.isEmpty }

    var text: String { value as! String }

    var outside: XCUICoordinate { coordinate(withNormalizedOffset: .zero).withOffset(.init(dx: -100, dy: 100)) }
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
