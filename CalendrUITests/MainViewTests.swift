//
//  MainViewTests.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

class MainViewTests: UITestCase {

    func testMainStatusItemClicked_ShouldDisplayMainView() {

        MenuBar.main.click()

        XCTAssertTrue(Main.view.didAppear)
        XCTAssertTrue(Main.view.buttons.firstMatch.isHittable)

        Main.view.outside.click()

        XCTAssertFalse(Main.view.buttons.firstMatch.isHittable)
    }

    func testEventStatusItemClicked_ShouldDisplayEventDetails() {

        XCTAssertTrue(MenuBar.event.waitForExistence(timeout: 1))

        MenuBar.event.click()

        XCTAssertTrue(EventDetails.view.waitForExistence(timeout: 1))
        XCTAssertTrue(EventDetails.view.didAppear)

        EventDetails.view.outside.click()

        XCTAssertFalse(EventDetails.view.exists)
    }

    // TODO: Click settings button and check that it opens SettingsViewController
    // TODO: Click calendar button and check that it opens Calendar.app
}
