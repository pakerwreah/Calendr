//
//  AutoLauncher.swift
//  Calendr
//
//  Created by Paker on 29/12/22.
//

import AppKit
import ServiceManagement

@objc protocol AutoLaunching: AnyObject where Self: NSObject {
    @objc dynamic var isLoginItemEnabled: Bool { get set }
    @objc dynamic var isLaunchAgentEnabled: Bool { get set }
    func syncStatus()
}

class AutoLauncher: NSObject, AutoLaunching {

    private let launchServices: LaunchServiceProviding
    private let localStorage: LocalStorageProvider

    private var loginItem: LaunchService { launchServices.loginItem }
    private var launchAgent: LaunchService { launchServices.launchAgent }

    init(launchServices: LaunchServiceProviding, localStorage: LocalStorageProvider) {

        self.launchServices = launchServices
        self.localStorage = localStorage

        super.init()

        isLoginItemEnabled = loginItem.isEnabled

        // we unregister the agent on a clean exit
        // so we have to restore it on every launch
        isLaunchAgentEnabled = localStorage.launchAgentEnabled
    }

    // prevent side effects on toggle rollback
    private var loginItemToggleLocked = false

    @objc dynamic lazy var isLoginItemEnabled: Bool = loginItem.isEnabled {
        didSet {
            guard oldValue != isLoginItemEnabled, !loginItemToggleLocked else { return }

            loginItemToggleLocked = true
            defer { loginItemToggleLocked = false }

            toggleRegistration(&isLoginItemEnabled, for: loginItem)
        }
    }

    // prevent side effects on toggle rollback
    private var launchAgentToggleLocked = false

    @objc dynamic lazy var isLaunchAgentEnabled: Bool = launchAgent.isEnabled {
        didSet {
            let newValue = isLaunchAgentEnabled
            guard oldValue != newValue, !launchAgentToggleLocked else { return }

            launchAgentToggleLocked = true
            defer { launchAgentToggleLocked = false }

            toggleRegistration(&isLaunchAgentEnabled, for: launchAgent)

            if newValue && !isLaunchAgentEnabled {
                // if it fails to enable, keep the previous storage value
            } else {
                localStorage.launchAgentEnabled = isLaunchAgentEnabled
            }
        }
    }

    private func toggleRegistration(_ enabled: inout Bool, for service: LaunchService) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            if !BuildConfig.isTesting {
                print(error)
            }
        }
        if enabled != service.isEnabled {
            enabled.toggle()
        }
    }

    func syncStatus() {
        isLoginItemEnabled = loginItem.isEnabled
        isLaunchAgentEnabled = launchAgent.isEnabled
    }
}
