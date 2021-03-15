//
//  NSButton+Rx.swift
//  Calendr
//
//  Created by Paker on 26/01/21.
//

import Cocoa
import RxSwift

extension Reactive where Base: NSButton {

    public var titleColor: Binder<NSColor?> {
        Binder(self.base) { button, color in
            button.setTitleColor(color: color)
        }
    }
}
