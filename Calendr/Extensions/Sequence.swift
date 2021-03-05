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
}