//
//  MockAutoLauncher.swift
//  Calendr
//
//  Created by Paker on 21/05/2026.
//

#if DEBUG

import Foundation

class MockAutoLauncher: NSObject, AutoLaunching {
    @objc dynamic var isEnabled: Bool = false
    func syncStatus() { }
}

#endif
