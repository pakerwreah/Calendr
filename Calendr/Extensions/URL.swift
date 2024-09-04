//
//  URL.swift
//  Calendr
//
//  Created by Paker on 04/09/2024.
//

import Foundation

extension URL {
    var domain: String? {
        if #available(macOS 13.0, *) {
            host()
        } else {
            host
        }
    }
}
