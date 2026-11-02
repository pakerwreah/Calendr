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
    func testChangeSystemTimeZone_withEmptyCustomTimeZone_shouldUpdateCalendarWithSystemTimeZone() {

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

    @Test
    func testChangeSystemTimeZone_withValidCustomTimeZone_shouldNotOverrideCustomTimeZone() {

        localStorage.timeZone = "America/Los_Angeles"

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        #expect(dateProvider.calendar.timeZone.identifier == "America/Los_Angeles")
        #expect(updatedCalendar.value == nil)

        system.calendar = .gregorian.with(timeZone: .init(identifier: "Asia/Tokyo")!)
        notificationCenter.post(name: .NSSystemTimeZoneDidChange, object: nil)

        #expect(dateProvider.calendar.timeZone.identifier == "America/Los_Angeles")
        #expect(updatedCalendar.value?.timeZone.identifier == "America/Los_Angeles")
    }

    @Test
    func testChangeCustomTimeZone_withValidCustomTimeZone_shouldUpdateCalendarWithCustomTimeZone() {

        let system = MockSystemTimeProvider()
        let dateProvider = makeDateProvider(system: system)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        #expect(dateProvider.calendar.timeZone.identifier == "GMT")
        #expect(updatedCalendar.value == nil)

        localStorage.timeZone = "Europe/London"

        #expect(dateProvider.calendar.timeZone.identifier == "Europe/London")
        #expect(updatedCalendar.value?.timeZone.identifier == "Europe/London")
    }

    @Test func testCustomTimeZone_shouldUpdateCalendarAtCustomMidnight() {

        localStorage.timeZone = "Europe/Berlin"

        let system = MockSystemTimeProvider(
            date: .make(year: 2026, month: 11, day: 2, hour: 21)
        )
        let scheduler = HistoricalScheduler()
        let dateProvider = makeDateProvider(system: system, scheduler: scheduler)
        let updatedCalendar = observeCalendarUpdates(from: dateProvider)

        let format = "dd/MM/yyyy HH:mm"
        let systemFormatter = DateFormatter(format: format, calendar: system.calendar)
        let customFormatter = DateFormatter(format: format, calendar: dateProvider.calendar)

        #expect(systemFormatter.string(from: dateProvider.now) == "02/11/2026 21:00")
        #expect(customFormatter.string(from: dateProvider.now) == "02/11/2026 22:00")

        #expect(updatedCalendar.value == nil)

        system.date.addTimeInterval(3600)
        scheduler.advance(1, .hour)

        #expect(updatedCalendar.value == nil)

        system.date.addTimeInterval(3600)
        scheduler.advance(1, .hour)

        #expect(updatedCalendar.value != nil)

        #expect(systemFormatter.string(from: dateProvider.now) == "02/11/2026 23:00")
        #expect(customFormatter.string(from: dateProvider.now) == "03/11/2026 00:00")
    }

    func makeDateProvider(
        system: DateProvider.SystemTimeProviding,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> DateProvider {

        DateProvider(
            notificationCenter: notificationCenter,
            localStorage: localStorage,
            scheduler: scheduler,
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
