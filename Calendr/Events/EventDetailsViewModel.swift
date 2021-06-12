//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Foundation
import RxSwift

class EventDetailsViewModel {

    let title: String
    let duration: String
    let url: String
    let location: String
    let notes: String

    let popoverMaterial: Observable<PopoverMaterial>

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        settings: EventSettings
    ) {

        title = event.title
        url = (event.type.isBirthday ? nil : event.url?.absoluteString) ?? ""
        location = event.location ?? ""
        notes = event.notes ?? ""

        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = dateProvider.calendar

        if event.isAllDay {
            formatter.timeStyle = .none
            duration = formatter.string(from: event.start, to: event.start)
        } else {
            formatter.timeStyle = .short

            let meta = EventMeta(event: event, dateProvider: dateProvider)

            let end: Date

            if event.type.isReminder {
                end = event.start
            }
            else if meta.isSingleDay && meta.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            duration = formatter.string(from: event.start, to: end)
        }

        popoverMaterial = settings.popoverMaterial
    }
}
