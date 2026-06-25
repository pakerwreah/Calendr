//
//  CacheTests.swift
//  CalendrTests
//
//  Created by Paker on 07/09/2024.
//

import Foundation
import Testing
@testable import Calendr

class CacheTests {

    @Test func testCapacity() {

        let cache = LRUCache<String, String>(capacity: 2)
        cache.set("K1", "V1")
        cache.set("K2", "V2")
        cache.set("K3", "V3")

        #expect(cache.get("K1") == nil)
        #expect(cache.get("K2") == "V2")
        #expect(cache.get("K3") == "V3")
    }

    @Test func testDropLeastRecentlyUsed() {

        let cache = LRUCache<String, String>(capacity: 2)
        cache.set("K1", "V1")
        cache.set("K2", "V2")

        #expect(cache.get("K1") == "V1")

        cache.set("K3", "V3")

        #expect(cache.get("K1") == "V1")
        #expect(cache.get("K2") == nil)
        #expect(cache.get("K3") == "V3")

        cache.set("K4", "V4")

        #expect(cache.get("K1") == nil)
        #expect(cache.get("K3") == "V3")
        #expect(cache.get("K4") == "V4")

        cache.remove("K4")

        #expect(cache.get("K4") == nil)

        cache.set("K5", "V5")

        #expect(cache.get("K3") == "V3")
        #expect(cache.get("K5") == "V5")
    }
}
