//
//  DueDate.swift
//  Calendr
//
//  Created by Paker on 24/10/2025.
//


struct DueDate {
    let date: Date

    static func withCurrentTime(
        at date: Date,
        adding increment: DateComponents,
        using dateProvider: DateProviding
    ) -> Self {

        let calendar = dateProvider.calendar
        let currentTime = calendar.dateComponents([.hour, .minute], from: dateProvider.now)

        guard
            let hour = currentTime.hour,
            let minute = currentTime.minute,
            let combined = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date),
            let dueDate = calendar.date(byAdding: increment, to: combined)
        else {
            print("🔥 Could not calculate due date")
            return .init(date: dateProvider.now)
        }

        return .init(date: dueDate)
    }
}
