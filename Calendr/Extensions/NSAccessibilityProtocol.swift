//
//  NSAccessibilityProtocol.swift
//  Calendr
//
//  Created by Paker on 15/07/2021.
//

import AppKit

extension NSAccessibilityProtocol {

    func setAccessibilityIdentifiers(_ accessibilityIdentifiers: [String]) {

        setAccessibilityIdentifier(accessibilityIdentifiers.joined(separator: ","))
    }
}
