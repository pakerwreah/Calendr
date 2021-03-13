//
//  NSViewController+Rx.swift
//  Calendr
//
//  Created by Paker on 13/03/2021.
//

import RxSwift

extension Reactive where Base: NSViewController {

    var viewDidLoad: Observable<Void> {
        methodInvoked(#selector(Base.viewDidLoad)).toVoid()
    }

    var viewWillAppear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillAppear)).toVoid()
    }

    var viewDidAppear: Observable<Void> {
        methodInvoked(#selector(Base.viewDidAppear)).toVoid()
    }

    var viewWillDisappear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillDisappear)).toVoid()
    }

    var viewDidDisappear: Observable<Void> {
        methodInvoked(#selector(Base.viewDidDisappear)).toVoid()
    }

    var viewWillLayout: Observable<Void> {
        methodInvoked(#selector(Base.viewWillLayout)).toVoid()
    }

    var viewDidLayout: Observable<Void> {
        methodInvoked(#selector(Base.viewDidLayout)).toVoid()
    }
}
