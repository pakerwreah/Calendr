//
//  NSViewController+Rx.swift
//  Calendr
//
//  Created by Paker on 13/03/2021.
//

import AppKit
import RxSwift

extension Reactive where Base: NSViewController {

    var viewDidLoad: Observable<Void> {
        methodInvoked(#selector(Base.viewDidLoad)).void()
    }

    var viewWillAppear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillAppear)).void()
    }

    var viewDidAppear: Observable<Void> {
        methodInvoked(#selector(Base.viewDidAppear)).void()
    }

    var viewWillDisappear: Observable<Void> {
        methodInvoked(#selector(Base.viewWillDisappear)).void()
    }

    var viewDidDisappear: Observable<Void> {
        methodInvoked(#selector(Base.viewDidDisappear)).void()
    }

    var viewWillLayout: Observable<Void> {
        methodInvoked(#selector(Base.viewWillLayout)).void()
    }

    var viewDidLayout: Observable<Void> {
        methodInvoked(#selector(Base.viewDidLayout)).void()
    }
}
