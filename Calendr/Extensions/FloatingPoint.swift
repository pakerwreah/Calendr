//
//  FloatingPoint.swift
//  Calendr
//
//  Created by Paker on 12/11/2025.
//

extension FloatingPoint {
    func rounded(to step: Self) -> Self {
        (self / step).rounded() * step
    }
}
