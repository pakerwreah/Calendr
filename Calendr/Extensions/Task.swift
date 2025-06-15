//
//  Task.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

extension Task where Success == Never, Failure == Never {

    static func sleep(seconds: TimeInterval) async {
        try? await sleep(nanoseconds: 1_000_000_000 * UInt64(seconds))
    }
}
