//
//  AutoLauncher.swift
//  Calendr
//
//  Created by Paker on 29/12/22.
//

import AppKit
import ServiceManagement

class AutoLauncher: NSObject {
    @objc dynamic var isEnabled: Bool = false
    func syncStatus() { }
}

@available(macOS 13.0, *)
private class AppAutoLauncher: AutoLauncher {

    @objc dynamic override var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print(error)
            }
            syncStatus()
        }
    }

    override func syncStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}

extension AutoLauncher {

    static let `default`: AutoLauncher = {
        if #available(macOS 13.0, *) {
            return AppAutoLauncher()
        } else {
            return AutoLauncher()
        }
    }()
}
