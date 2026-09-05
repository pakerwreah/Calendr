//
//  OperatingSystemVersion.swift
//  Calendr
//
//  Created by Paker on 05/09/2026.
//

import Foundation

extension OperatingSystemVersion {

    init?(_ string: String) {

        let parts = string.split(separator: ".").compactMap { Int($0) }

        guard let major = parts.first else { return nil }

        let minor = parts[safe: 1] ?? 0
        let patch = parts[safe: 2] ?? 0

        self.init(
            majorVersion: major,
            minorVersion: minor,
            patchVersion: patch
        )
    }

    var description: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}

func isOperatingSystemAtLeast(_ targetOS: String) -> Bool {

    guard let osVersion = OperatingSystemVersion(targetOS) else { return false }

    return ProcessInfo.processInfo.isOperatingSystemAtLeast(osVersion)
}
