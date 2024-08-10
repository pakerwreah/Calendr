//
//  Environment.swift
//  Calendr
//
//  Created by Paker on 10/08/2024.
//

import Foundation

protocol EnvironmentProviding {

    static var SENTRY_DSN: String? { get }
}

extension EnvironmentProviding {

    static var SENTRY_DSN: String? { nil }
}
