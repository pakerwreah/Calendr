//
//  UITestCase.swift
//  UITestCase
//
//  Created by Paker on 11/07/2021.
//

import XCTest

class UITestCase: XCTestCase {

    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-AppleLanguages", "(en)"]
        app.launch()
    }
}
