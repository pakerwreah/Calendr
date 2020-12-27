//
//  CALayer+Rx.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import RxSwift
import RxCocoa

extension Reactive where Base: CALayer {

    public var backgroundColor: Binder<CGColor> {
        return Binder(self.base) { layer, color in
            layer.backgroundColor = color
        }
    }

    public var borderColor: Binder<CGColor> {
        return Binder(self.base) { layer, color in
            layer.borderColor = color
        }
    }

}
