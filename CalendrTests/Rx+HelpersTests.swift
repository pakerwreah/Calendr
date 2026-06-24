//
//  Rx+HelpersTests.swift
//  Calendr
//
//  Created by Paker on 07/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class RxHelpersTests {

    let scheduler = HistoricalScheduler()

    @Test func testBatch_shouldNotProduceEmptyResults() async {

        let batchExpectation = expectation(description: "Batch")

        let subject = PublishSubject<Int>()

        var result: [Int]?

        _ = subject.batch(timeSpan: .milliseconds(1), scheduler: scheduler).bind {
            #expect($0.isEmpty == false)
            result = $0
            batchExpectation.fulfill()
        }

        scheduler.advance(.milliseconds(1))

        #expect(result == nil)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)

        scheduler.advance(.milliseconds(1))

        #expect(result == [1,2,3])

        result = nil

        scheduler.advance(.milliseconds(1))

        #expect(result == nil)

        await fulfillment(of: [batchExpectation])
    }
}
