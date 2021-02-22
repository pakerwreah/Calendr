//
//  CalendarModel.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
@testable import Calendr

extension CalendarModel {
    static func make(
        identifier: String = "",
        account: String = "",
        title: String = "",
        color: CGColor = .clear
    ) -> CalendarModel {

        .init(
            identifier: identifier,
            account: account,
            title: title,
            color: color
        )
    }
}
