//
//  Sequence.swift
//  Calendr
//
//  Created by Paker on 03/03/2021.
//

import Foundation

extension Sequence {

    func prevMap<T>(_ transform: ((prev: Element?, curr: Element)) throws -> T) rethrows -> [T] {
        var prev: Element? = nil
        return try map { curr -> T in
            defer { prev = curr }
            return try transform((prev, curr))
        }
    }

    func compact<T>() -> [T] where Element == T? {
        compactMap { $0 }
    }

    func flatten() -> [Element.Element] where Element: Sequence {
        flatMap { $0 }
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}

extension LazySequenceProtocol {

    func compact<T>() -> LazyMapSequence<LazyFilterSequence<LazyMapSequence<Elements, T?>>, T> where Element == T? {
        compactMap { $0 }
    }
}
