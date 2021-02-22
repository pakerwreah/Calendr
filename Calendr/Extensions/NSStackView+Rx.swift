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
        Binder(self.base) { stackView, views in
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            views.forEach(stackView.addArrangedSubview)
        }
    }

    public var isContentHidden: Observable<Bool> {
        Observable.combineLatest(
            base.arrangedSubviews.map {
                $0.rx.observe(\.isHidden)
            }
        ).map { $0.allSatisfy { $0 } }
    }
}
