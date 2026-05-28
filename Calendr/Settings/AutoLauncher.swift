//
//  AutoLauncher.swift
//  Calendr
//
//  Created by Paker on 29/12/22.
//

import AppKit
import ServiceManagement
import Sentry

@objc protocol AutoLaunching: AnyObject where Self: NSObject {
    @objc dynamic var isEnabled: Bool { get set }
    func syncStatus()
    func terminate()
}

class AutoLauncher: NSObject, AutoLaunching {

    private let mainApp = SMAppService.mainApp
    private let launcher = SMAppService.agent(plistName: "br.paker.Calendr.launcher.plist")

    override init() {
        super.init()
        Task {
            do {
                try await initLauncher()
            } catch {
                print(error)
            }
            syncStatus()
        }
    }

    private func initLauncher() async throws {
        // always unregister at load so we can update the launcher config
        switch launcher.status {
            case .notFound:
                SentrySDK.capture(message: "Launch agent not found")
            case .enabled:
                try await launcher.unregister()
            default: ()
        }
    }

    @objc dynamic var isEnabled: Bool = false {
        didSet {
            guard oldValue != isEnabled else { return }
            do {
                if isEnabled {
                    try mainApp.register()
                    try launcher.register()
                } else {
                    try mainApp.unregister()
                    try launcher.unregister()
                }
            } catch {
                print(error)
            }
            syncStatus()
        }
    }

    func syncStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func terminate() {
        Task { @MainActor in
            if launcher.status == .enabled {
                try? await launcher.unregister()
            }
            NSApp.terminate(nil)
        }
    }
}
