//
//  NSText+Rx.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import RxSwift
import RxCocoa

extension Reactive where Base: NSText {

    public var string: Binder<String> {
        return Binder(self.base) { text, string in
            text.string = string
        }
    }

}
