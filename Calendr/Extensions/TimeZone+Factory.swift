//
//  TimeZone+Factory.swift
//  Calendr
//
//  Created by Paker on 20/01/22.
//

import Foundation

extension TimeZone {

    static let utc = TimeZone(identifier: "UTC")!
    static let shanghai = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone(secondsFromGMT: 8 * 3600)!
}
