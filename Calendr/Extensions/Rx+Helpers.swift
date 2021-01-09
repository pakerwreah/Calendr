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

    public func matching(_ value: Element) -> Observable<Element> where Element: Equatable {
        filter { value ~= $0 }
    }
}

extension PublishSubject {

    static func pipe() -> (output: Observable<Element>, input: AnyObserver<Element>) {
        { ($0.asObservable(), $0.asObserver()) }(Self.init())
    }
}

extension Bool {
    var isFalse: Bool { !self }
}
