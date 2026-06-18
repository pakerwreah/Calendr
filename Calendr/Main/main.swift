//
//  main.swift
//  Calendr
//
//  Created by Paker on 17/01/21.
//

import Cocoa

#if SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE
Bundle.swizzleResourceBundleAccessor()
#endif

private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
