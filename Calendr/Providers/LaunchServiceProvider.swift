//
//  LaunchServiceProvider.swift
//  Calendr
//
//  Created by Paker on 31/05/2026.
//

import AppKit
import ServiceManagement

protocol LaunchServiceProviding {
    var loginItem: LaunchService { get }
    var launchAgent: LaunchService { get }

    @MainActor
    func relaunch(at url: URL) async throws
    func terminate()
}

protocol LaunchService {

    var isEnabled: Bool { get }

    func register() throws
    func unregister() throws
    func unregister() async throws
}

protocol AppKiller {
    func terminate()
}

class LaunchServiceProvider: LaunchServiceProviding {

    let loginItem: LaunchService
    let launchAgent: LaunchService

    private let terminator: () -> Void

    init (
        loginItem: LaunchService = SMAppService.mainApp,
        launchAgent: LaunchService = SMAppService.agent(plistName: "br.paker.Calendr.launcher.plist"),
        terminator: @escaping () -> Void = { NSApp.terminate(nil) }
    ) {
        self.loginItem = loginItem
        self.launchAgent = launchAgent
        self.terminator = terminator
    }

    func relaunch(at url: URL) async throws {
        try await terminate(relaunchUrl: url)
    }

    func terminate() {
        Task {
            try? await terminate(relaunchUrl: nil)
        }
    }

    @MainActor
    private func terminate(relaunchUrl: URL?) async throws {

        try? await launchAgent.unregister()

        if let url = relaunchUrl {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = ["-n", url.path]
            try task.run()
            task.waitUntilExit()
        }

        terminator()
    }
}

extension SMAppService: LaunchService {

    var isEnabled: Bool {
        status == .enabled
    }
}
