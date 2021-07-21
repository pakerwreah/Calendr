//
//  NSView+Rx.swift
//  Calendr
//
//  Created by Paker on 13/03/2021.
//

import AppKit
import RxSwift

extension Reactive where Base: NSView {

    var mouseEntered: Observable<Void> {
        methodInvoked(#selector(Base.mouseEntered)).void()
    }

    var mouseExited: Observable<Void> {
        methodInvoked(#selector(Base.mouseExited)).void()
    }

    var isHovered: Observable<Bool> {
        .merge(
            mouseEntered.map(true),
            mouseExited.map(false)
        )
    }

    var updateLayer: Observable<Void> {
        methodInvoked(#selector(Base.updateLayer)).void()
    }
}
