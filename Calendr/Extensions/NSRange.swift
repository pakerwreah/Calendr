//
//  NSRange.swift
//  Calendr
//
//  Created by Paker on 25/09/2026.
//

import Foundation

extension NSRange {

    func intersects(_ ranges: [NSRange]) -> Bool {
        ranges.contains { NSIntersectionRange(self, $0).length > 0 }
    }
}
