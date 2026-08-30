//
//  ChineseCalendarSupport.swift
//  Calendr
//
//  Created by Paker on 30/08/2026.
//

import Foundation

enum ChineseCalendarSupport {

    static func isSupported(_ preferredLocalizations: [String]) -> Bool {
        preferredLocalizations.lazy.map(Localizations.baseLanguageCode).contains("zh")
    }
}
