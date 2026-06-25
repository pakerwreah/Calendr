//
//  SwiftTests.swift
//  Calendr
//
//  Created by Paker on 24/06/2026.
//

import Foundation
import Testing

class Expectation: CustomStringConvertible {

    var description: String { comment.description }

    var isInverted = false
    var expectedFulfillmentCount = 1

    private let comment: Comment
    private let sourceLocation: SourceLocation

    private var sleep: Task<(), Error>?
    private var confirm: Confirmation?
    private var fulfillmentCount = 0
    private var finished = false

    fileprivate var fulfilledAt: Date?

    private let timeout: Duration = .milliseconds(100)

    init(description: Comment, sourceLocation: SourceLocation = #_sourceLocation) {
        self.comment = description
        self.sourceLocation = sourceLocation
    }

    func fulfill() {
        guard !finished else { return }
        sleep?.cancel()
        fulfilledAt = .now
        fulfillmentCount += 1
        confirm?()
    }

    fileprivate func wait() async {

        let expectedCount = isInverted ? 0 : expectedFulfillmentCount

        await confirmation(
            comment,
            expectedCount: expectedCount,
            sourceLocation: sourceLocation,
        ) { confirm in
            defer { finished = true }
            self.confirm = confirm

            for _ in 0..<fulfillmentCount {
                confirm()
            }

            guard expectedCount == 0 || fulfillmentCount < expectedCount else { return }

            self.sleep = Task {
                try await Task.sleep(for: timeout)
            }
            try? await sleep?.value
        }
    }
}

typealias expectation = Expectation

func fulfillment(
    of expectations: [Expectation],
    enforceOrder: Bool = false,
    sourceLocation: SourceLocation = #_sourceLocation
) async {

    await withTaskGroup { group in
        for expectation in expectations {
            group.addTask {
                await expectation.wait()
            }
        }
    }
    guard enforceOrder else { return }

    var previous: Expectation?

    for expectation in expectations {
        guard let fulfilledAt = expectation.fulfilledAt else { continue }

        if let previous, fulfilledAt < previous.fulfilledAt ?? .distantPast {
            Issue.record(
                "Expectation '\(expectation)' fulfilled before '\(previous)'",
                sourceLocation: sourceLocation
            )
        }
        previous = expectation
    }
}
