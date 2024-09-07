//
//  CacheTests.swift
//  CalendrTests
//
//  Created by Paker on 07/09/2024.
//

import XCTest
@testable import Calendr

class CacheTests: XCTestCase {

    func testCapacity() {

        let cache = LRUCache<String, String>(capacity: 2)
        cache.set("K1", "V1")
        cache.set("K2", "V2")
        cache.set("K3", "V3")

        XCTAssertNil(cache.get("K1"))
        XCTAssertEqual(cache.get("K2"), "V2")
        XCTAssertEqual(cache.get("K3"), "V3")
    }

    func testDropLeastRecentlyUsed() {

        let cache = LRUCache<String, String>(capacity: 2)
        cache.set("K1", "V1")
        cache.set("K2", "V2")

        XCTAssertEqual(cache.get("K1"), "V1")

        cache.set("K3", "V3")

        XCTAssertEqual(cache.get("K1"), "V1")
        XCTAssertNil(cache.get("K2"))
        XCTAssertEqual(cache.get("K3"), "V3")

        cache.set("K4", "V4")

        XCTAssertNil(cache.get("K1"))
        XCTAssertEqual(cache.get("K3"), "V3")
        XCTAssertEqual(cache.get("K4"), "V4")

        cache.remove("K4")

        XCTAssertNil(cache.get("K4"))

        cache.set("K5", "V5")

        XCTAssertEqual(cache.get("K3"), "V3")
        XCTAssertEqual(cache.get("K5"), "V5")
    }
}
