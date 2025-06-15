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
        email: String? = nil,
        title: String = "",
        color: NSColor = .clear,
        isSubscribed: Bool = false
    ) -> CalendarModel {

        .init(
            id: id,
            account: .init(title: account, email: email),
            title: title,
            color: color,
            isSubscribed: isSubscribed
        )
    }
}

#endif
