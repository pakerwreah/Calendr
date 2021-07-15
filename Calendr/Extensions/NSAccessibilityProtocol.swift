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

    func addAccessibilityChild(_ accessibilityChild: NSObject) {

        let children = accessibilityChildren() ?? []

        if !children.isEmpty {
            assert(children.allSatisfy { $0 as! NSObject != accessibilityChild })
        }

        setAccessibilityChildren(children + [accessibilityChild])
    }

    func removeAccessibilityChild(_ accessibilityChild: NSObject) {

        guard let children = accessibilityChildren(), !children.isEmpty else { return assertionFailure() }

        let newChildren = children.filter { $0 as! NSObject != accessibilityChild }

        assert(newChildren.count == children.count - 1)

        setAccessibilityChildren(newChildren)
    }
}
