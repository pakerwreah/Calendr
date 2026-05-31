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
    func terminate()
}

protocol LaunchService {

    var isEnabled: Bool { get }

    func register() throws
    func unregister() throws
    func unregister() async throws
}

class LaunchServiceProvider: LaunchServiceProviding {

    let loginItem: LaunchService = SMAppService.mainApp
    let launchAgent: LaunchService = SMAppService.agent(plistName: "br.paker.Calendr.launcher.plist")

    func terminate() { NSApp.terminate(nil) }
}

extension SMAppService: LaunchService {

    var isEnabled: Bool {
        status == .enabled
    }
}
