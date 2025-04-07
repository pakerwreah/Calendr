//
//  CalendarModel+Factory.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

#if DEBUG

import AppKit

extension CalendarModel {
    
    static func make(
        id: String = "",
        account: String = "",
        title: String = "",
        color: NSColor = .clear,
        isSubscribed: Bool = false
    ) -> CalendarModel {

        .init(
            id: id,
            account: account,
            title: title,
            color: color,
            isSubscribed: isSubscribed
        )
    }
}

#endif
