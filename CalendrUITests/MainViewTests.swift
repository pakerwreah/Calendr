//
//  MainViewTests.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

class MainViewTests: UITestCase {

    func testMainStatusItemClicked_shouldDisplayMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertTrue(Main.pinBtn.isHittable)

        Main.view.outside.click()

        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testPinButtonClicked_shouldNotHideMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertTrue(Main.pinBtn.isHittable)

        app.activate()

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testEventStatusItemClicked_shouldDisplayEventDetails() {

        MenuBar.event.wait(.eventTimeout).click()

        XCTAssertTrue(EventDetails.view.didAppear)

        EventDetails.view.outside.click()

        XCTAssertFalse(EventDetails.view.exists)
    }

    func testRemindersButtonClicked_shouldOpenRemindersApp() {

        let reminders = XCUIApplication(
            url: NSWorkspace.shared.urlForApplication(toOpen: URL(string: "x-apple-reminderkit://")!)!
        )

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)

        Main.remindersBtn.click()

        XCTAssert(app.wait(for: .runningBackground, timeout: 1))
        XCTAssert(reminders.wait(for: .runningForeground, timeout: 1))

        reminders.terminate()
    }

    func testCalendarButtonClicked_shouldOpenCalendarApp() {

        let calendar = XCUIApplication(url: NSWorkspace.shared.urlForApplication(toOpen: URL(string: "webcal://")!)!)

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)

        Main.calendarBtn.click()

        XCTAssert(app.wait(for: .runningBackground, timeout: 1))
        XCTAssert(calendar.wait(for: .runningForeground, timeout: 1))

        calendar.terminate()
    }

    func testPickerButtonClicked_shouldOpenCalendarPicker() {

        MenuBar.main.click()
        Main.pickerBtn.click()

        XCTAssertTrue(CalendarPicker.view.didAppear)

        CalendarPicker.view.outside.click()

        XCTAssertFalse(CalendarPicker.view.exists)
    }

    func testSettingsButtonClicked_shouldOpenSettings() {

        MenuBar.main.click()
        Main.settingsBtn.click()

        XCTAssertTrue(Settings.window.didAppear)
        XCTAssertTrue(Settings.view.didAppear)

        Settings.window.buttons[XCUIIdentifierCloseWindow].click()

        XCTAssertFalse(Settings.window.exists)
    }
}
