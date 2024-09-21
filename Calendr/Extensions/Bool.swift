//
//  Bool.swift
//  Calendr
//
//  Created by Paker on 21/05/22.
//

import Foundation

extension Bool: @retroactive Comparable {

    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        (lhs ? 0 : 1) < (rhs ? 0 : 1)
    }
}
