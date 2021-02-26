//
//  String.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Foundation

extension StringProtocol {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
