//
//  DateFormatter.swift
//  Calendr
//
//  Created by Paker on 01/01/21.
//

import Foundation

extension DateFormatter {

    convenience init(calendar: Calendar) {
        self.init()
        self.calendar = calendar
        self.locale = calendar.locale
        self.timeZone = calendar.timeZone
    }

    convenience init(format: String, calendar: Calendar) {
        self.init(calendar: calendar)
        dateFormat = format
    }

    convenience init(template: String, calendar: Calendar) {
        self.init(calendar: calendar)
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
