//
//  NSAccessibilityProtocol+Rx.swift
//  Calendr
//
//  Created by Paker on 15/07/2021.
//

import Cocoa
import RxSwift

extension Reactive where Base: NSAccessibilityProtocol {

    var accessibilityIdentifier: Binder<String?> {
        Binder(self.base) { object, identifier in
            object.setAccessibilityIdentifier(identifier)
        }
    }

    var accessibilityIdentifiers: Binder<[String]> {
        Binder(self.base) { object, identifiers in
            object.setAccessibilityIdentifiers(identifiers)
        }
    }
}
