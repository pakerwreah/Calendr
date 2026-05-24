//
//  BuildConfig.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Foundation
#if canImport(CalendrObjC)
import CalendrObjC
#endif

enum BuildConfig {

    static let date = String(cString: BUILD_DATE)
    static let time = String(cString: BUILD_TIME)
    static let appVersion = "v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)"
    static let isSandboxed = ProcessInfo.processInfo.environment.keys.contains("APP_SANDBOX_CONTAINER_ID")
    static let isPreview = ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS")
    static let isTesting = NSClassFromString("XCTestCase") != nil

    #if DEBUG
    static let isDebug = true
    static let isUITesting = CommandLine.arguments.contains("-uitest")
    #else
    static let isDebug = false
    static let isUITesting = false
    #endif
}
