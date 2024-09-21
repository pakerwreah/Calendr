//
//  DisposableWrapper.swift
//  Calendr
//
//  Created by Paker on 21/09/2024.
//

import Cocoa
import RxSwift

protocol DisposableWrapping {
    associatedtype Value

    func disposed(by bag: DisposeBag) -> Value
}

struct DisposableWrapper<T>: DisposableWrapping {

    private let value: T
    private let disposable: Disposable

    init(value: T, disposable: Disposable) {
        self.value = value
        self.disposable = disposable
    }

    func disposed(by bag: DisposeBag) -> T {
        bag.insert(disposable)
        return value
    }
}

struct CompositeDisposableWrapper<Wrapped: DisposableWrapping>: DisposableWrapping {

    private let wrappers: [Wrapped]

    static func create(_ wrappers: [Wrapped]) -> Self {
        .init(wrappers: wrappers)
    }

    func disposed(by bag: DisposeBag) -> [Wrapped.Value] {

        wrappers.map { $0.disposed(by: bag) }
    }
}
