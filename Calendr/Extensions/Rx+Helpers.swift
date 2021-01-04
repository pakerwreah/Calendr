//
//  Rx+Helpers.swift
//  Calendr
//
//  Created by Paker on 27/12/20.
//

import RxSwift

extension ObservableType {

    public func toVoid() -> Observable<Void> {
        return map { _ in () }
    }

    public func toOptional() -> Observable<Element?> {
        map { value -> Element? in value }
    }
}

extension PublishSubject {

    static func pipe() -> (input: AnyObserver<Element>, output: Observable<Element>) {
        { ($0.asObserver(), $0.asObservable()) }(Self.init())
    }
}
