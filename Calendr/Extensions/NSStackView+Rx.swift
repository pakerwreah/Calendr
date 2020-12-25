//
//  NSStackView+Rx.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import RxSwift
import RxCocoa

extension Reactive where Base: NSStackView {

    public var arrangedSubviews: Binder<[NSView]> {
        return Binder(self.base) { stackView, views in
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            views.forEach(stackView.addArrangedSubview)
        }
    }

}
