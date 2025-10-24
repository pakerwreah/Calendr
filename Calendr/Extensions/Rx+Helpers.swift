//
//  Rx+Helpers.swift
//  Calendr
//
//  Created by Paker on 27/12/20.
//

import RxSwift

extension ObservableConvertibleType {

    static func void() -> Observable<Void> { .just(()) }

    func bind<T: AnyObject>(to object: T, _ keyPath: ReferenceWritableKeyPath<T, Element>) -> Disposable {

        asObservable().bind { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

extension ObservableType {

    func void() -> Observable<Void> {
        map { _ in () }
    }

    func map<T>(_ value: T) -> Observable<T> {
        map { _ in value }
    }

    func optional() -> Observable<Element?> {
        map { value -> Element? in value }
    }

    func matching(_ values: Element...) -> Observable<Element> where Element: Equatable {
        filter { values.contains($0) }
    }

    func skipNil<T>() -> Observable<T> where Element == T? {
        compactMap { $0 }
    }

    func `repeat`<T: ObservableType>(when other: T) -> Observable<Element> where T.Element == Void {
        Observable.combineLatest(self, other.startWith(())).map(\.0)
    }

    func lastValue() -> Element? {
        var value: Element? = nil
        _ = bind { value = $0 }
        return value
    }
}

extension PublishSubject {

    static func pipe(on scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> (output: Observable<Element>, input: AnyObserver<Element>) {
        { ($0.asObservable().observe(on: scheduler), $0.asObserver()) }(Self.init())
    }
}

extension BehaviorSubject {

    static func pipe(value: Element, on scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> (output: Observable<Element>, input: AnyObserver<Element>) {
        { ($0.asObservable().observe(on: scheduler), $0.asObserver()) }(Self.init(value: value))
    }

    var current: Element { try! value() }
}

extension Bool {
    var isFalse: Bool { !self }
    var isTrue: Bool { self }
}

extension Optional {
    var isNil: Bool { self == nil }
    var isNotNil: Bool { self != nil }
}

extension AnyObserver {

    static func dummy() -> Self { .init { _ in } }
}

extension PrimitiveSequence where Trait == CompletableTrait, Element == Never {

    func mapError<T>(_ transform: @escaping (Error) -> T) -> Maybe<T> {

        asObservable().materialize().flatMap { event -> Maybe<T> in
            switch event {
                case .error(let e):
                    return .just(transform(e))
                case .next, .completed:
                    return .empty()
            }
        }
        .asMaybe()
    }
}
