//
//  Collection.swift
//  Calendr
//
//  Created by Paker on 03/03/2021.
//

import Foundation

extension Collection {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    subscript(clamped index: Index) -> Element? {
        index < startIndex ? first : index >= endIndex ? last : self[index]
    }

    var last: Element? {
        isEmpty ? nil : self[self.index(startIndex, offsetBy: count - 1)]
    }

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

    func sorted<T: Comparable>(by getter: (Element) -> T) -> [Element] {
        sorted { getter($0) < getter($1) }
    }

    func distinct<T: Hashable>(by selector: (Element) -> T) -> [Element] {
        var seen: Set<T> = []
        var result: [Element] = []
        for element in self {
            let property = selector(element)
            if seen.insert(property).inserted {
                result.append(element)
            }
        }
        return result
    }
}
