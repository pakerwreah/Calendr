//
//  ProcessInfo.swift
//  Calendr
//
//  Created by Paker on 15/08/2024.
//

import Foundation

extension ProcessInfo {

    enum Architecture: String {
        case x86_64
        case arm64
    }

    var architecture: Architecture? { _architecture }
}

/// Equivalent to running `uname -m` in shell
private var _architecture: ProcessInfo.Architecture? = {
    var sysinfo = utsname()
    let result = uname(&sysinfo)
    guard result == EXIT_SUCCESS else { return nil }
    let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
    guard let identifier = String(bytes: data, encoding: .ascii) else { return nil }
    return .init(rawValue: identifier.trimmingCharacters(in: .controlCharacters))
}()
