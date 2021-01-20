//
//  Rx+Helpers.swift
//  Calendr
//
//  Created by Paker on 27/12/20.
//

import RxSwift

extension ObservableType {

    func toVoid() -> Observable<Void> {
        return map { _ in () }
    }

    func toOptional() -> Observable<Element?> {
        map { value -> Element? in value }
    }

    func matching(_ value: Element) -> Observable<Element> where Element: Equatable {
        filter { value ~= $0 }
    }
}

extension PublishSubject {

    static func pipe() -> (output: Observable<Element>, input: AnyObserver<Element>) {
        { ($0.asObservable(), $0.asObserver()) }(Self.init())
    }
}

extension BehaviorSubject {

    static func pipe(value: Element) -> (output: Observable<Element>, input: AnyObserver<Element>) {
        { ($0.asObservable(), $0.asObserver()) }(Self.init(value: value))
    }
}

extension Bool {
    var isFalse: Bool { !self }
}
