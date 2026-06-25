//
//  LaunchServiceProviderTests.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

import Foundation
import Testing
@testable import Calendr

class LaunchServiceProviderTests {

    @Test func testTermination() async {

        let unregisterExpectation = expectation(description: "Unregister")
        let terminateExpectation = expectation(description: "Terminate")

        let loginItem = MockLaunchService()
        let launchAgent = MockLaunchService()

        let launchServices = LaunchServiceProvider(
            loginItem: loginItem,
            launchAgent: launchAgent,
            terminator: terminateExpectation.fulfill
        )

        launchAgent.spyUnregisterAsync = {
            try await Task.sleep(for: .milliseconds(10))
            unregisterExpectation.fulfill()
        }

        launchServices.terminate()

        await fulfillment(of: [unregisterExpectation, terminateExpectation], enforceOrder: true)
    }
}
