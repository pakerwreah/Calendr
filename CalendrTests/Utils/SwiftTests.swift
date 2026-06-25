//
//  SwiftTests.swift
//  Calendr
//
//  Created by Paker on 24/06/2026.
//

import Testing
import Foundation

class Expectation: CustomStringConvertible {

    var description: String { comment.description }

    var isInverted = false
    var expectedFulfillmentCount = 1

    private let comment: Comment
    private let sourceLocation: SourceLocation
    private var sleep: Task<(), Error>?
    private var confirm: Confirmation?

    private(set) var fulfilledAt: Date?
    private var fulfillmentCount = 0

    init(description: Comment, sourceLocation: SourceLocation = #_sourceLocation) {
        self.comment = description
        self.sourceLocation = sourceLocation
    }

    func fulfill() {
        fulfillmentCount += 1
        sleep?.cancel()
        confirm?()
        fulfilledAt = .now
    }

    fileprivate func wait(timeout: Double) async -> Void {

        let expectedCount = isInverted ? 0 : expectedFulfillmentCount

        await confirmation(
            comment,
            expectedCount: expectedCount,
            sourceLocation: sourceLocation,
        ) { confirm in

            for _ in 0..<fulfillmentCount {
                confirm()
            }

            guard expectedCount == 0 || fulfillmentCount < expectedCount else { return }

            self.confirm = confirm

            self.sleep = Task {
                try await Task.sleep(for: .milliseconds(timeout * 1000))
            }
            try? await sleep?.value
        }
    }
}

typealias expectation = Expectation

func fulfillment(
    of expectations: [Expectation],
    enforceOrder: Bool = false,
    timeout: Double = 0.1,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    var previous: Expectation?

    for expectation in expectations {
        await expectation.wait(timeout: timeout)

        guard enforceOrder, let fulfilledAt = expectation.fulfilledAt else { continue }

        if let previous, fulfilledAt < previous.fulfilledAt ?? .distantPast {
            Issue.record(
                "Expectation '\(expectation)' fulfilled before '\(previous)'",
                sourceLocation: sourceLocation
            )
        }
        previous = expectation
    }
}
