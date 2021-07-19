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
        Main.settingsBtn.click()

        XCTAssertEqual(Settings.tabs.map(\.title), ["General", "Calendars", "About"])
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
    }

    func testSettingsAboutQuitClicked_shouldCloseApp() {

        MenuBar.main.click()
        Main.settingsBtn.click()
        Settings.Tab.about.click()
        Settings.About.quitBtn.click()

        XCTAssertEqual(app.state, .notRunning)
    }
}
