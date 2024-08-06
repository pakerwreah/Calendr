//
//  SettingsTests.swift
//  CalendrUITests
//
//  Created by Paker on 18/07/2021.
//

import XCTest

class SettingsTests: UITestCase {

    func testSettingsTabs() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        XCTAssertEqual(Settings.tabs.map(\.title), ["General", "Calendars", "Shortcuts", "About"])
        XCTAssertTrue(Settings.General.view.didAppear)

        XCTAssertFalse(Settings.Calendars.view.didAppear)
        Settings.Tab.calendars.click()
        XCTAssertTrue(Settings.Calendars.view.didAppear)

        XCTAssertFalse(Settings.About.view.didAppear)
        Settings.Tab.about.click()
        XCTAssertTrue(Settings.About.view.didAppear)

        XCTAssertFalse(Settings.General.view.didAppear)
        Settings.Tab.general.click()
        XCTAssertTrue(Settings.General.view.didAppear)

        XCTAssertFalse(Settings.Keyboard.view.didAppear)
        Settings.Tab.keyboard.click()
        XCTAssertTrue(Settings.Keyboard.view.didAppear)
    }

    func testSettingsAbout_withQuitClicked_shouldCloseApp() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        Settings.Tab.about.click()
        Settings.About.quitBtn.click()

        XCTAssert(app.wait(for: .notRunning, timeout: 1))
    }

    func testSettingsCalendarPicker() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        Settings.Tab.calendars.click()

        let checkbox = Settings.Calendars.view.checkBoxes
            .element(matching: .title("Personal"))

        XCTAssert(checkbox.waitForExistence(timeout: 1))

        let initial = Calendar.events.count

        XCTAssert(initial > 0)

        checkbox.click()

        XCTAssertEqual(Calendar.events.count, initial - 1)

        // click label
        checkbox.coordinate(withNormalizedOffset: .init(dx: 0.3, dy: 0.5)).click()

        XCTAssertEqual(Calendar.events.count, initial)
    }

    func testSettingsGeneral_toggleShowIcon() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let showIcon = Settings.General.view.checkBoxes
            .element(matching: .title("Show icon"))

        showIcon.click()
        XCTAssertEqual(showIcon.value(), false)
        XCTAssertNotIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        showIcon.click()
        XCTAssertEqual(showIcon.value(), true)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")
    }

    func testSettingsGeneral_toggleShowDate() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let showDate = Settings.General.view.checkBoxes
            .element(matching: .title("Show date"))

        showDate.click()
        XCTAssertEqual(showDate.value(), false)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertNotIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        showDate.click()
        XCTAssertEqual(showDate.value(), true)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")
    }

    func testSettingsGeneral_toggleShowDateOffWithShowIconOff() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let showIcon = Settings.General.view.checkBoxes
            .element(matching: .title("Show icon"))

        let showDate = Settings.General.view.checkBoxes
            .element(matching: .title("Show date"))

        showIcon.click()
        XCTAssertEqual(showIcon.value(), false)
        XCTAssertEqual(showDate.value(), true)
        XCTAssertNotIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        showDate.click()
        XCTAssertEqual(showIcon.value(), true)
        XCTAssertEqual(showDate.value(), false)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertNotIn(MenuBar.main.identifiers, "Friday 1 January 2021")
    }

    func testSettingsGeneral_toggleShowIconOffWithShowDateOff() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let showIcon = Settings.General.view.checkBoxes
            .element(matching: .title("Show icon"))

        let showDate = Settings.General.view.checkBoxes
            .element(matching: .title("Show date"))

        showDate.click()
        XCTAssertEqual(showIcon.value(), true)
        XCTAssertEqual(showDate.value(), false)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertNotIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        showIcon.click()
        XCTAssertEqual(showIcon.value(), true)
        XCTAssertEqual(showDate.value(), false)
        XCTAssertIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertNotIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        showDate.click()
        XCTAssertEqual(showIcon.value(), false)
        XCTAssertEqual(showDate.value(), true)
        XCTAssertNotIn(MenuBar.main.identifiers, Accessibility.MenuBar.Main.Icon.calendar)
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")
    }

    func testSettingsGeneral_toggleShowNextEvent() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let checkbox = Settings.General.view.checkBoxes
            .element(matching: .title("Show next event"))

        XCTAssertTrue(MenuBar.event.waitForExistence(timeout: .longTimeout))
        XCTAssertTrue(MenuBar.reminder.waitForExistence(timeout: .longTimeout))

        checkbox.click()
        XCTAssertFalse(MenuBar.event.waitForExistence(timeout: .longTimeout))
        XCTAssertFalse(MenuBar.reminder.waitForExistence(timeout: .longTimeout))

        checkbox.click()
        XCTAssertTrue(MenuBar.event.waitForExistence(timeout: .longTimeout))
        XCTAssertTrue(MenuBar.reminder.waitForExistence(timeout: .longTimeout))
    }

    func testSettingsGeneral_changeDateFormat() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let dropdown = Settings.General.dateFormatDropdown
        let input = Settings.General.dateFormatInput

        XCTAssertEqual(dropdown.value(), "Friday 1 January 2021")
        XCTAssertIn(MenuBar.main.identifiers, "Friday 1 January 2021")

        dropdown.click()
        dropdown.menuItems.element(boundBy: 0).click()

        XCTAssertEqual(dropdown.value(), "01/01/2021")
        XCTAssertIn(MenuBar.main.identifiers, "01/01/2021")

        dropdown.click()
        dropdown.menuItems.allElementsBoundByIndex.last?.click()

        XCTAssertEqual(dropdown.value(), "Custom...")
        XCTAssertIn(MenuBar.main.identifiers, "Fri 1 Jan 2021")

        input.typeKey(.delete, modifierFlags: [])
        XCTAssertIn(MenuBar.main.identifiers, "???")

        input.typeText("E")
        XCTAssertIn(MenuBar.main.identifiers, "Fri")
    }

    func testSettingsGeneral_toggleShowWeekNumbers() throws {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let checkbox = Settings.General.view.checkBoxes
            .element(matching: .title("Show week numbers"))

        XCTAssert(try XCTUnwrap(Calendar.weekNumbers.first).isHittable)

        checkbox.click()
        XCTAssert(Calendar.weekNumbers.isEmpty)

        checkbox.click()
        XCTAssert(try XCTUnwrap(Calendar.weekNumbers.first).isHittable)
    }

    func testSettingsGeneral_toggleShowDeclinedEvents() {

        MenuBar.main.click()
        Main.openSettings()

        XCTAssert(Settings.view.didAppear)

        let checkbox = Settings.General.view.checkBoxes
            .element(matching: .title("Show declined events"))

        XCTAssertEqual(checkbox.value(), false)

        let initial = Calendar.events.count

        checkbox.click()
        XCTAssertEqual(checkbox.value(), true)
        XCTAssertEqual(Calendar.events.count, initial + 1)

        checkbox.click()
        XCTAssertEqual(checkbox.value(), false)
        XCTAssertEqual(Calendar.events.count, initial)
    }

    func testSettingsGeneral_togglePreserveSelectedDate() {

        MenuBar.main.click()

        Calendar.dates[6].click()
        XCTAssertEqual(Calendar.selected.value(), "2")

        Main.view.outside.click()
        MenuBar.main.click()

        XCTAssertEqual(Calendar.selected.value(), "1")

        Main.openSettings()
        XCTAssert(Settings.view.didAppear)

        let checkbox = Settings.General.view.checkBoxes
            .element(matching: .title("Preserve selected date on hide"))

        checkbox.click()

        Settings.window.buttons[XCUIIdentifierCloseWindow].click()

        Calendar.dates[6].click()
        XCTAssertEqual(Calendar.selected.value(), "2")

        Main.view.outside.click()
        MenuBar.main.click()

        XCTAssertEqual(Calendar.selected.value(), "2")
    }
}
