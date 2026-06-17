//
//  MockLaunchServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/05/2026.
//

#if DEBUG

import Foundation

class MockLaunchService: LaunchService {

    var isEnabled: Bool = false

    var spyRegister: () throws -> Void = { }
    var spyUnregister: () throws -> Void = { }
    var spyUnregisterAsync: () async throws -> Void = { }

    func register() throws { try spyRegister() }
    func unregister() throws { try spyUnregister() }
    func unregister() async throws { try await spyUnregisterAsync() }
}

class MockLaunchServiceProvider: LaunchServiceProviding {

    let loginItem: LaunchService
    let launchAgent: LaunchService

    var didTerminate: (() -> Void)?
    var didRelaunch: ((URL) throws -> Void)?

    init(
        loginItem: LaunchService = MockLaunchService(),
        launchAgent: LaunchService = MockLaunchService()
    ) {
        self.loginItem = loginItem
        self.launchAgent = launchAgent
    }

    func terminate() { didTerminate?() }

    func relaunch(at url: URL) throws {
        try didRelaunch?(url)
    }
}

#endif
