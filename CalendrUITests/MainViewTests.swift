//
//  MainViewTests.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

class MainViewTests: UITestCase {

    func waitFadeAnimation() { Thread.sleep(forTimeInterval: 0.5) }

    func testMainStatusItemClicked_shouldDisplayMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertTrue(Main.pinBtn.isHittable)

        Main.view.outside.click()

        waitFadeAnimation()
        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testPinButtonClicked_shouldNotHideMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertEqual(app.state, .runningForeground)

        Main.pinBtn.click()
        Main.view.outside.click()

        waitFadeAnimation()
        XCTAssertTrue(Main.pinBtn.isHittable)

        app.activate()

        Main.pinBtn.click()
        Main.view.outside.click()

        waitFadeAnimation()
        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    func testEventStatusItemClicked_shouldDisplayEventDetails() {

        MenuBar.event.click()

        XCTAssertTrue(EventDetails.view.didAppear)

        EventDetails.view.outside.click()

        waitFadeAnimation()
        XCTAssertFalse(EventDetails.view.exists)
    }

    func testRemindersButtonClicked_shouldOpenRemindersApp() {

        let reminders = XCUIApplication(
            url: NSWorkspace.shared.urlForApplication(toOpen: URL(string: "x-apple-reminderkit://")!)!
        )

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertEqual(app.state, .runningForeground)

        Main.remindersBtn.click()

        XCTAssert(app.wait(for: .runningBackground, timeout: 1))
        XCTAssert(reminders.wait(for: .runningForeground, timeout: 1))

        reminders.terminate()
    }

    func testCalendarButtonClicked_shouldOpenCalendarApp() {

        let calendar = XCUIApplication(url: NSWorkspace.shared.urlForApplication(toOpen: URL(string: "webcal://")!)!)

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertEqual(app.state, .runningForeground)

        Main.calendarBtn.click()

        XCTAssert(app.wait(for: .runningBackground, timeout: 1))
        XCTAssert(calendar.wait(for: .runningForeground, timeout: 1))

        calendar.terminate()
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
