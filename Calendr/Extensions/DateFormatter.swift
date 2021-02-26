//
//  DateFormatter.swift
//  Calendr
//
//  Created by Paker on 01/01/21.
//

import Foundation

extension DateFormatter {

    convenience init(locale: Locale?, context: Context = .unknown) {
        self.init()
        self.locale = locale
        self.formattingContext = context
    }

    convenience init(format: String, locale: Locale?, context: Context = .unknown) {
        self.init(locale: locale, context: context)
        dateFormat = format
    }

    convenience init(template: String, locale: Locale?, context: Context = .unknown) {
        self.init(locale: locale, context: context)
        setLocalizedDateFormatFromTemplate(template)
    }
}
