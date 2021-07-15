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

    // TODO: Click event status item and check it opens the popover
    // TODO: Click settings button and check that it opens SettingsViewController
    // TODO: Click calendar button and check that it opens Calendar.app
}
