//
//  DummyTest.swift
//  CalendrUITests
//
//  Created by Paker on 11/07/2021.
//

import XCTest

class DummyTest: UITestCase {

    func testForever() {
        _ = app.wait(for: .notRunning, timeout: .infinity)
    }
}
