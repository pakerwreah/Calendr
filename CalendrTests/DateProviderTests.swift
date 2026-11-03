//
//  DateProviderTests.swift
//  Calendr
//
//  Created by Paker on 02/11/2026.
//

import Foundation
import RxSwift
import Testing

@testable import Calendr

class DateProviderTests {

    let notificationCenter = NotificationCenter()
    let localStorage = MockLocalStorageProvider()

    @Test func testChangeDay_shouldUpdateCalendar() {

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        #expect(updatedCalendar.value == nil)

        notificationCenter.post(name: .NSCalendarDayChanged, object: nil)

        #expect(updatedCalendar.value != nil)
    }

    @Test func testChangeSystemLocale_shouldUpdateCalendar() {

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        system.calendar = .gregorian.with(locale: Locale(identifier: "fr_FR"))
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        #expect(dateProvider.calendar.locale?.identifier == "fr_FR")
        #expect(updatedCalendar.value?.locale?.identifier == "fr_FR")
    }

    @Test func testChangeFirstWeekday_shouldUpdateCalendar() {

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        #expect(dateProvider.calendar.firstWeekday == 1)
        #expect(updatedCalendar.value == nil)

        localStorage.firstWeekday = 2

        #expect(dateProvider.calendar.firstWeekday == 2)
        #expect(updatedCalendar.value?.firstWeekday == 2)
    }

    @Test
    func testChangeSystemTimeZone_shouldUpdateCalendarWithSystemTimeZone() {

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        #expect(dateProvider.calendar.timeZone.identifier == "GMT")
        #expect(updatedCalendar.value == nil)

        system.calendar = .gregorian.with(timeZone: .init(identifier: "Asia/Tokyo")!)
        notificationCenter.post(name: .NSSystemTimeZoneDidChange, object: nil)

        #expect(dateProvider.calendar.timeZone.identifier == "Asia/Tokyo")
        #expect(updatedCalendar.value?.timeZone.identifier == "Asia/Tokyo")
    }

    func makeDateProvider(
        system: DateProvider.SystemTimeProviding
    ) -> DateProvider {

        DateProvider(
            notificationCenter: notificationCenter,
            localStorage: localStorage,
            system: system
        )
    }

    private func observeCalendarUpdates(from dateProvider: DateProvider) -> CalendarUpdate {
        let update = CalendarUpdate()
        dateProvider.calendarUpdated
            .bind { update.value = $0 }
            .disposed(by: update.disposeBag)
        return update
    }
}

private class MockSystemTimeProvider: DateProvider.SystemTimeProviding {
    var date: Date
    var calendar: Calendar

    init(
        date: Date = .make(year: 2026, month: 11, day: 2, hour: 12),
        calendar: Calendar = .gregorian.with(locale: Locale(identifier: "en_US"))
    ) {
        self.date = date
        self.calendar = calendar
    }
}

private class CalendarUpdate {
    var value: Calendar?
    let disposeBag = DisposeBag()
}
