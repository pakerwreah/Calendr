//
//  KVCTests.swift
//  Calendr
//
//  Created by Paker on 19/11/2025.
//

import XCTest
@testable import Calendr

class KVCTests: XCTestCase {

    func testExistingKey() {

        XCTAssertNoThrow(XCTAssertEqual(try TestObject().safeValue(forKey: "testKey"), "testValue"))
    }

    func testNonExistingKey() {

        XCTAssertThrowsError(try TestObject().safeValue(forKey: "missingKey") as String) { error in

            guard case KVCError.unknownKey(key: "missingKey", in: "TestObject") = error else {
                return XCTFail()
            }
        }
    }

    func testExistingKeyWrongType() {

        XCTAssertThrowsError(try TestObject().safeValue(forKey: "testKey") as Int) { error in

            guard case KVCError.typeMismatch(key: "testKey", source: "NSTaggedPointerString", target: "Int") = error else {
                return XCTFail()
            }
        }
    }
}

private class TestObject: NSObject {
    @objc let testKey: String = "testValue"
}
