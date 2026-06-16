//
//  BundleInfo.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

import Foundation

struct BundleInfo {
    let bundleURL: URL
    let bundleIdentifier: String?
}

extension BundleInfo {

    static let main = Self.init(
        bundleURL: Bundle.main.bundleURL,
        bundleIdentifier: Bundle.main.bundleIdentifier
    )
}
