//
//  NSControl.swift
//  Calendr
//
//  Created by Paker on 18/12/2024.
//

import RxSwift
import Cocoa

extension Reactive where Base: NSControl {
    /// Observable sequence that emits when the text field gains or loses focus
    var hasFocus: Observable<Bool> {
        Observable.merge(
            NotificationCenter.default.rx
                .notification(NSControl.textDidBeginEditingNotification, object: base)
                .map(true),
            NotificationCenter.default.rx
                .notification(NSControl.textDidEndEditingNotification, object: base)
                .map(false)
        )
    }
}
