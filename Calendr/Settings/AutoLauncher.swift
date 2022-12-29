//
//  AutoLauncher.swift
//  Calendr
//
//  Created by Paker on 29/12/22.
//

import AppKit
import RxSwift
import ServiceManagement

class AutoLauncher: NSObject {
    @objc dynamic var isEnabled: Bool = false
}

@available(macOS 13.0, *)
private class AppAutoLauncher: AutoLauncher {

    @objc dynamic override var isEnabled: Bool {
        get {
            SMAppService.mainApp.status ~= .enabled
        }
        set {
            guard newValue != isEnabled else { return }
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print(error)
            }
        }
    }

    private let disposeBag = DisposeBag()

    override init() {
        super.init()
        setUpBindings()
    }

    private func setUpBindings() {

        NSApp.rx.observe(\.keyWindow)
            .filter { $0?.contentViewController is SettingsViewController }
            .compactMap { [weak self] _ in self?.isEnabled }
            .bind(to: rx.isEnabled)
            .disposed(by: disposeBag)
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
