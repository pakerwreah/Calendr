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
        XCTAssertEqual(app.state, .runningForeground)

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertTrue(Main.pinBtn.isHittable)

        Main.pinBtn.click()
        Main.view.outside.click()

        XCTAssertFalse(Main.pinBtn.isHittable)
    }

    // TODO: Click event status item and check it opens the popover
    // TODO: Click settings button and check that it opens SettingsViewController
    // TODO: Click calendar button and check that it opens Calendar.app
}
