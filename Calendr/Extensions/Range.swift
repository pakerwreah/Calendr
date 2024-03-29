//
//  Range.swift
//  Calendr
//
//  Created by Paker on 29/03/24.
//

import Foundation

extension ClosedRange where Bound == Int {

    /// Returns the index after the given index, looping through the range if index is out of bounds.
    func circular(after i: Bound) -> Bound {
        let normalized = (i - lowerBound + count) % count
        return (normalized + 1) % count + lowerBound
    }

    /// Returns the index before the given index, looping through the range if index is out of bounds.
    func circular(before i: Bound) -> Bound {
        let normalized = (i - lowerBound + count) % count
        return (normalized - 1 + count) % count + lowerBound
    }
}
