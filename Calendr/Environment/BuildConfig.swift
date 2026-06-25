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
    static let appVersion = "v\((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0")"
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "br.paker.Calendr"
    static let isSandboxed = ProcessInfo.processInfo.environment.keys.contains("APP_SANDBOX_CONTAINER_ID")
    static let isPreview = ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS")
    static let isTesting = ProcessInfo.processInfo.isTesting

    #if DEBUG
    static let isDebug = true
    static let isUITesting = CommandLine.arguments.contains("-uitest")
    #else
    static let isDebug = false
    static let isUITesting = false
    #endif
}

/// source: xctest-dynamic-overlay
extension ProcessInfo {
  fileprivate var isTesting: Bool {
    if environment.keys.contains("XCTestBundlePath") { return true }
    if environment.keys.contains("XCTestBundleInjectPath") { return true }
    if environment.keys.contains("XCTestConfigurationFilePath") { return true }
    if environment.keys.contains("XCTestSessionIdentifier") { return true }

    return arguments.contains { argument in
      let path = URL(fileURLWithPath: argument)
      return path.lastPathComponent == "swiftpm-testing-helper"
        || argument == "--testing-library"
        || path.lastPathComponent == "xctest"
        || path.pathExtension == "xctest"
    }
  }
}
