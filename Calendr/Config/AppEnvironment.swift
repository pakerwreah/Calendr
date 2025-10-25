//
//  AppEnvironment.swift
//  Calendr
//
//  Created by Paker on 10/08/2024.
//

import Foundation

protocol AppEnvironmentProviding {

    static var SENTRY_DSN: String? { get }
}

extension AppEnvironmentProviding {

    static var SENTRY_DSN: String? { nil }
}
