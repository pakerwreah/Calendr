//
//  UITestCase.swift
//  UITestCase
//
//  Created by Paker on 11/07/2021.
//

import XCTest

class UITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
    }

    override func tearDown() {
        app = nil
    }
}
