//
//  UITestCase.swift
//  UITestCase
//
//  Created by Paker on 11/07/2021.
//

import XCTest

class UITestCase: XCTestCase {

    override func setUp() {

        continueAfterFailure = false

        // 🔨 Prevent timeout while synthesizing click event
        // when running tests from command line (don't ask me)
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
        finder.coordinate(withNormalizedOffset: .zero).hover()

        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-AppleLanguages", "(en)"]
        app.launch()
    }
}
