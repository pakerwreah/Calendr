//
//  NSControl.swift
//  Calendr
//
//  Created by Paker on 18/12/2024.
//

import Cocoa
import RxSwift

extension Reactive where Base: NSControl {

    var hasFocus: Observable<Bool> {
        base.rx
            .observe(\.window?.firstResponder)
            .map { [weak base] _ in
                base?.hasFocus ?? false
            }
            .distinctUntilChanged()
    }
}
