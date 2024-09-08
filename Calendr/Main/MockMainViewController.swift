//
//  MockMainViewController.swift
//  Calendr
//
//  Created by Paker on 11/07/2021.
//

#if DEBUG

import AppKit.NSWorkspace
import UserNotifications

class MockMainViewController: MainViewController {

    init() {

        let dateProvider = MockDateProvider(start: .make(year: 2021, month: 1, day: 1, hour: 15, minute: 45))

        let userDefaults = UserDefaults(suiteName: Self.className())!
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: Self.className())

        registerDefaultPrefs(in: userDefaults)

        userDefaults.setValuesForKeys([
            Prefs.firstWeekday: dateProvider.calendar.firstWeekday,
            Prefs.statusItemDateStyle: DateFormatter.Style.full.rawValue,
            Prefs.showWeekNumbers: true,
            Prefs.showEventStatusItem: true,
            Prefs.transparencyLevel: 5,
            Prefs.enabledCalendars: CalendarModel.all.map(\.id)
        ])

        let notificationCenter = NotificationCenter()
        let fileManager = FileManager.default

        super.init(
            autoLauncher: AutoLauncher(),
            workspace: NSWorkspace.shared,
            calendarService: MockCalendarServiceProvider(dateProvider: dateProvider),
            geocoder: MockGeocodeServiceProvider(),
            weatherService: MockWeatherServiceProvider(),
            dateProvider: dateProvider,
            screenProvider: ScreenProvider(notificationCenter: notificationCenter), 
            notificationProvider: MockLocalNotificationProvider(),
            networkProvider: MockNetworkServiceProvider(),
            userDefaults: userDefaults,
            notificationCenter: notificationCenter, 
            fileManager: fileManager
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private typealias TimeFactory = (_ hour: Int, _ minute: Int) -> Date
private typealias EventFactory = (TimeFactory) -> [EventModel]

private func eventsIn(year: Int, month: Int, day: Int, factory: EventFactory) -> [EventModel] {

    func time(hour: Int, minute: Int) -> Date {
        .make(year: year, month: month, day: day, hour: hour, minute: minute)
    }

    return factory(time)
}

private extension CalendarModel {

    private static var uuid: String { UUID().uuidString  }

    static let gmail = make(id: uuid, account: "Google", title: "Gmail", color: .systemRed)
    static let personal = make(id: uuid, account: "iCloud", title: "Personal", color: .systemYellow)
    static let reminders = make(id: uuid, account: "iCloud", title: "Reminders", color: .systemOrange)
    static let birthdays = make(id: uuid, account: "Other", title: "Birthdays", color: .systemGray)
    static let meetings = make(id: uuid, account: "Work", title: "Meetings", color: .systemGreen)
    static let tasks = make(id: uuid, account: "Work", title: "Tasks", color: .systemTeal)

    static let all: [Self] = [.gmail, .personal, .reminders, .birthdays, .meetings, .tasks]
}

private extension EventModel {

    static func testEvent(year: Int, month: Int, start: Int, end: Int) -> EventModel {
        .make(
            start: .make(year: year, month: month, day: start),
            end: .make(year: year, month: month, day: end),
            title: "Test event 🚧",
            calendar: .personal
        )
    }
}

private extension MockCalendarServiceProvider {

    convenience init(dateProvider: DateProviding) {
        self.init(
            events: [
                eventsIn(year: 2021, month: 1, day: 1) { time in
                    [
                        .make(
                            start: time(15, 30),
                            end: time(15, 50),
                            title: "Drink some tea 🫖",
                            calendar: .personal
                        ),
                        .make(
                            start: time(16, 00),
                            end: time(17, 00),
                            title: "Update Calendr screenshot 📷",
                            calendar: .tasks
                        ),
                        .make(
                            start: time(17, 00),
                            end: time(18, 00),
                            title: "Some meeting 👔",
                            location: "https://zoom.us/j/9999999999",
                            calendar: .meetings
                        ),
                        .make(
                            start: time(18, 30),
                            end: time(18, 45),
                            title: "Declined event 🙅🏻‍♂️",
                            notes: "Not interested",
                            type: .event(.declined),
                            calendar: .gmail
                        ),
                        .make(
                            start: time(19, 00),
                            title: "Take the trash out",
                            type: .reminder,
                            calendar: .reminders
                        )
                    ]
                },
                [
                    .testEvent(year: 2020, month: 12, start: 28, end: 30),
                    .testEvent(year: 2021, month: 1, start: 4, end: 8),
                    .testEvent(year: 2021, month: 1, start: 11, end: 15),
                    .testEvent(year: 2021, month: 1, start: 18, end: 22),
                    .testEvent(year: 2021, month: 1, start: 25, end: 29),
                    .testEvent(year: 2021, month: 2, start: 1, end: 5)
                ]
            ]
            .flatten(),
            calendars: CalendarModel.all,
            dateProvider: dateProvider
        )
    }
}

#endif
