//
//  CollectionTests.swift
//  Calendr
//
//  Created by Paker on 03/06/2026.
//

import XCTest
@testable import Calendr

class CollectionTests: XCTestCase {

    func testSafeSubscriptOperator() {

        XCTAssertNil([][safe: 0])
        XCTAssertNil(["a"][safe: 1])
        XCTAssertNil(["a"][safe: -1])
    }

    func testClampedSubscriptOperator() {

        XCTAssertNil([][clamped: -1])
        XCTAssertNil([][clamped: 0])
        XCTAssertNil([][clamped: 1])

        XCTAssertEqual(["a"][clamped: -1], "a")
        XCTAssertEqual(["a"][clamped: 0], "a")
        XCTAssertEqual(["a"][clamped: 1], "a")

        XCTAssertEqual(["a", "b"][clamped: -1], "a")
        XCTAssertEqual(["a", "b"][clamped: 0], "a")
        XCTAssertEqual(["a", "b"][clamped: 1], "b")
        XCTAssertEqual(["a", "b"][clamped: 2], "b")

        XCTAssertEqual(["a", "b", "c"][clamped: -1], "a")
        XCTAssertEqual(["a", "b", "c"][clamped: 0], "a")
        XCTAssertEqual(["a", "b", "c"][clamped: 1], "b")
        XCTAssertEqual(["a", "b", "c"][clamped: 2], "c")
        XCTAssertEqual(["a", "b", "c"][clamped: 3], "c")
    }
}
