//
//  Strings.swift
//  Calendr
//
//  Created by Paker on 20/02/2021.
//

import Foundation

extension Strings {

    static func lookupFunction(_ key: String, _ table: String) -> String {
        var string = Bundle.main.localizedString(forKey: key, value: "__nokey__", table: table)
        if string == "__nokey__" {
            string = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
                .localizedString(forKey: key, value: nil, table: table)
        }
        return string
    }
}
