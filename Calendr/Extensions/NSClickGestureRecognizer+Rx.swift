//
//  NSClickGestureRecognizer+Rx.swift
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

    @objc func clicked() {
        observer.onNext(())
    }
}

extension NSClickGestureRecognizer {

    typealias Configuration = (NSClickGestureRecognizer) -> Void
}

extension Reactive where Base: NSView {

    var click: Observable<Void> { click { _ in } }

    func click(_ configure: @escaping NSClickGestureRecognizer.Configuration) -> Observable<Void> {

        Observable.create { observer in

            let target = GestureProxy(observer)

            let click = NSClickGestureRecognizer(
                target: target,
                action: #selector(GestureProxy.clicked)
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
