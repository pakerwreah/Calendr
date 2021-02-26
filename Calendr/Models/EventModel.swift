//
//  EventModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Foundation

struct EventModel: Equatable {
    let start: Date
    let end: Date
    let title: String
    let location: String?
    let notes: String?
    let url: URL?
    let isAllDay: Bool
    let isPending: Bool
    let calendar: CalendarModel
}
