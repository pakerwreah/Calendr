//
//  KVCTests.swift
//  Calendr
//
//  Created by Paker on 19/11/2025.
//

import Foundation
import Testing
@testable import Calendr

class KVCTests {

    @Test func testExistingKey() throws {

        #expect(try TestObject().safeValue(forKey: "testKey") == "testValue")
    }

    @Test func testNonExistingKey() {

        #expect {
            _ = try TestObject().safeValue(forKey: "missingKey") as String
        } throws: { error in
            guard case KVCError.unknownKey(key: "missingKey", in: "TestObject") = error else {
                return false
            }
            return true
        }
    }

    @Test func testExistingKeyWrongType() {

        #expect {
            _ = try TestObject().safeValue(forKey: "testKey") as Int
        } throws: { error in
            guard case KVCError.typeMismatch(key: "testKey", source: "NSTaggedPointerString", target: "Int") = error else {
                return false
            }
            return true
        }
    }
}

private class TestObject: NSObject {
    @objc let testKey: String = "testValue"
}
