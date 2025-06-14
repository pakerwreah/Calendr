//
//  CalendarModel.swift
//  Calendr
//
//  Created by Paker on 31/12/20.
//

import Cocoa

struct CalendarAccount: Equatable {
    let title: String
    let email: String?
}

struct CalendarModel: Equatable {
    let id: String
    let account: CalendarAccount
    let title: String
    let color: NSColor
    let isSubscribed: Bool
}
