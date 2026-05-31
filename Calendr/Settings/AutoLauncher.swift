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
    @objc dynamic var isLoginItemEnabled: Bool { get set }
    @objc dynamic var isLaunchAgentEnabled: Bool { get set }
    func syncStatus()
    func terminate()
}

class AutoLauncher: NSObject, AutoLaunching {

    private let mainApp = SMAppService.mainApp
    private let launcher = SMAppService.agent(plistName: "br.paker.Calendr.launcher.plist")

    private let localStorage: LocalStorageProvider

    init(localStorage: LocalStorageProvider) {

        self.localStorage = localStorage

        super.init()

        isLoginItemEnabled = mainApp.isEnabled

        // we unregister the agent on a clean exit
        // so we have to restore it on every launch
        isLaunchAgentEnabled = localStorage.launchAgentEnabled
    }

    @objc dynamic lazy var isLoginItemEnabled: Bool = mainApp.isEnabled {
        didSet {
            guard oldValue != isLoginItemEnabled else { return }

            toggleRegistration(&isLoginItemEnabled, for: mainApp)
        }
    }

    // prevent side effects on toggle rollback
    private var launchAgentToggleLocked = false

    @objc dynamic lazy var isLaunchAgentEnabled: Bool = launcher.isEnabled {
        didSet {
            let newValue = isLaunchAgentEnabled
            guard oldValue != newValue, !launchAgentToggleLocked else { return }

            launchAgentToggleLocked = true
            defer { launchAgentToggleLocked = false }

            toggleRegistration(&isLaunchAgentEnabled, for: launcher)

            if newValue && !isLaunchAgentEnabled {
                // if it fails to enable, keep the previous storage value
            } else {
                localStorage.launchAgentEnabled = isLaunchAgentEnabled
            }
        }
    }

    private func toggleRegistration(_ enabled: inout Bool, for service: SMAppService) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print(error)
        }
        if enabled != service.isEnabled {
            enabled.toggle()
        }
    }

    func syncStatus() {
        isLoginItemEnabled = mainApp.isEnabled
        isLaunchAgentEnabled = launcher.isEnabled
    }

    func terminate() {
        Task { @MainActor in
            try? await launcher.unregister()
            NSApp.terminate(nil)
        }
    }
}

private extension SMAppService {

    var isEnabled: Bool { status == .enabled }
}
