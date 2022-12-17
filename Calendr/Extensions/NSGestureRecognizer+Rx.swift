//
//  NSGestureRecognizer+Rx.swift
//  Calendr
//
//  Created by Paker on 25/01/22.
//

import AppKit
import RxSwift

private class GestureProxy {

    private let observer: AnyObserver<Void>

    init(_ observer: AnyObserver<Void>) {
        self.observer = observer
    }

    @objc func recognized() {
        observer.onNext(())
    }
}

extension Reactive where Base: NSView {

    var click: Observable<Void> { click { _ in } }

    func click<T: NSClickGestureRecognizer> (_ configure: @escaping (T) -> Void) -> Observable<Void> {
        gesture(configure)
    }

    private func gesture<T: NSGestureRecognizer>(_ configure: @escaping (T) -> Void) -> Observable<Void> {

        Observable.create { observer in

            let target = GestureProxy(observer)

            let click = T.init(
                target: target,
                action: #selector(GestureProxy.recognized)
            )

            configure(click)

            base.addGestureRecognizer(click)

            return Disposables.create {
                _ = target // keep a strong reference
                base.removeGestureRecognizer(click)
            }
        }
        .share(replay: 1)
    }
}
