//
//  DateFormatter.swift
//  Calendr
//
//  Created by Paker on 01/01/21.
//

import Foundation

extension DateFormatter {
    convenience init(format: String) {
        self.init()
        dateFormat = format
    }

    convenience init(template: String, locale: Locale) {
        self.init()
        self.locale = locale
        setLocalizedDateFormatFromTemplate(template)
    }
}
