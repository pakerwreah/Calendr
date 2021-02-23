//
//  String.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import Foundation

extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var capitalizedFirst: String {
        prefix(1).capitalized + dropFirst()
    }
}
