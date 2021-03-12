//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import RxSwift

class EventDetailsViewModel {

    let title: String
    let duration: String
    let url: String
    let location: String
    let notes: String

    init?(identifier: String, dateProvider: DateProviding, calendarService: CalendarServiceProviding) {

        guard let event = calendarService.event(identifier) else { return nil }

        title = event.title
        url = event.url?.absoluteString ?? ""
        location = event.location ?? ""
        notes = event.notes ?? ""

        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = dateProvider.calendar

        if event.isAllDay {
            formatter.timeStyle = .none
            duration = formatter.string(from: event.startDate, to: event.startDate)
        } else {
            formatter.timeStyle = .short
            duration = formatter.string(from: event.startDate, to: event.endDate)
        }
    }
}
