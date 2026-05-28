//
//  BuildConfig.swift
//  Calendr
//
//  Created by Paker on 27/05/2026.
//

enum BuildConfig {
    static var isDebug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }
}
