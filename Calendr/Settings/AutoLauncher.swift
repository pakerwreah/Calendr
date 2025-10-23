//
//  AutoLauncher.swift
//  Calendr
//
//  Created by Paker on 29/12/22.
//

import AppKit
import ServiceManagement

class AutoLauncher: NSObject {

    @objc dynamic var isEnabled: Bool = false {
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

    func syncStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
