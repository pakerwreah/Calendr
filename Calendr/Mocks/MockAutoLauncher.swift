//
//  MockAutoLauncher.swift
//  Calendr
//
//  Created by Paker on 21/05/2026.
//

#if DEBUG

import Foundation

class MockAutoLauncher: NSObject, AutoLaunching {
    @objc dynamic var isLoginItemEnabled: Bool = false
    @objc dynamic var isLaunchAgentEnabled: Bool = false
    func syncStatus() { }
    func terminate() { }
}

#endif
