//
//  DateFormatter.swift
//  Calendr
//
//  Created by Paker on 01/01/21.
//

import Foundation

extension DateFormatter {

    convenience init(locale: Locale?) {
        self.init()
        self.locale = locale
    }

    convenience init(format: String, locale: Locale?) {
        self.init(locale: locale)
        dateFormat = format
    }

    convenience init(template: String, locale: Locale?) {
        self.init(locale: locale)
        setLocalizedDateFormatFromTemplate(template)
    }

    func with(context: Context) -> Self {
        formattingContext = context
        return self
    }

    func with(style: Style) -> Self {
        dateStyle = style
        return self
    }
}
