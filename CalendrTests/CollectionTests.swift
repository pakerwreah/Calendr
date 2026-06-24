//
//  CollectionTests.swift
//  Calendr
//
//  Created by Paker on 03/06/2026.
//

import Foundation
import Testing
@testable import Calendr

class CollectionTests {

    @Test func testSafeSubscriptOperator() {

        #expect([][safe: 0] == nil)
        #expect(["a"][safe: 1] == nil)
        #expect(["a"][safe: -1] == nil)
    }

    @Test func testClampedSubscriptOperator() {

        #expect([][clamped: -1] == nil)
        #expect([][clamped: 0] == nil)
        #expect([][clamped: 1] == nil)

        #expect(["a"][clamped: -1] == "a")
        #expect(["a"][clamped: 0] == "a")
        #expect(["a"][clamped: 1] == "a")

        #expect(["a", "b"][clamped: -1] == "a")
        #expect(["a", "b"][clamped: 0] == "a")
        #expect(["a", "b"][clamped: 1] == "b")
        #expect(["a", "b"][clamped: 2] == "b")

        #expect(["a", "b", "c"][clamped: -1] == "a")
        #expect(["a", "b", "c"][clamped: 0] == "a")
        #expect(["a", "b", "c"][clamped: 1] == "b")
        #expect(["a", "b", "c"][clamped: 2] == "c")
        #expect(["a", "b", "c"][clamped: 3] == "c")
    }
}
