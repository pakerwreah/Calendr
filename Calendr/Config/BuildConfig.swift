//
//  BuildConfig.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Foundation

enum BuildConfig {

    static let date = String(cString: BUILD_DATE)
    static let time = String(cString: BUILD_TIME)
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    static let isPreview = ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS")
    static let isTesting = NSClassFromString("XCTestCase") != nil
    static let isUITesting = CommandLine.arguments.contains("-uitest")
}
