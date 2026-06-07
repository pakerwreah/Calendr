//
//  Rx+HelpersTests.swift
//  Calendr
//
//  Created by Paker on 07/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class RxHelpersTests: XCTestCase {

    let scheduler = HistoricalScheduler()

    func testBatch_shouldNotProduceEmptyResults() {

        let batchExpectation = expectation(description: "Batch")

        let subject = PublishSubject<Int>()

        var result: [Int]?

        _ = subject.batch(timeSpan: .milliseconds(1), scheduler: scheduler).bind {
            XCTAssertNotNil($0)
            result = $0
            batchExpectation.fulfill()
        }

        scheduler.advance(.milliseconds(1))

        XCTAssertNil(result)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)

        scheduler.advance(.milliseconds(1))

        XCTAssertEqual(result, [1,2,3])

        result = nil

        scheduler.advance(.milliseconds(1))

        XCTAssertNil(result)

        wait(for: [batchExpectation], timeout: 0.1)
    }
}
