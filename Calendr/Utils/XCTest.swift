//
//  XCTest.swift
//  Calendr
//
//  Created by Paker on 06/08/2024.
//

import XCTest

func XCTAssertIn<T: Equatable>(_ collection: [T], _ element: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(collection.contains(element), "\(element) is not in \(collection)", file: file, line: line)
}

func XCTAssertNotIn<T: Equatable>(_ collection: [T], _ element: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertFalse(collection.contains(element), "\(element) is in \(collection)", file: file, line: line)
}
