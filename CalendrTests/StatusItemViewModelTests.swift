//
//  StatusItemViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 07/02/21.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class StatusItemViewModelTests {

    let disposeBag = DisposeBag()

    let dateChanged = PublishSubject<Void>()
    let calendarsSubject = BehaviorSubject<[String]>(value: [])

    let dateProvider = MockDateProvider()
    let screenProvider = MockScreenProvider()
    let calendarService = MockCalendarServiceProvider()
    let localStorage = MockLocalStorageProvider()
    let settings = MockStatusItemSettings()
    let scheduler = HistoricalScheduler()

    let notificationCenter = NotificationCenter()

    lazy var viewModel = StatusItemViewModel(
        dateChanged: dateChanged,
        nextEventCalendars: calendarsSubject,
        settings: settings,
        dateProvider: dateProvider,
        screenProvider: screenProvider,
        calendarService: calendarService,
        localStorage: localStorage,
        notificationCenter: notificationCenter,
        scheduler: scheduler
    )

    var iconsAndText: StatusItemViewModel.IconsAndText?
    var lastText: String? { iconsAndText?.text }
    var isVisible: Bool?

    init() {

        viewModel.iconsAndText
            .bind { [weak self] in
                self?.iconsAndText = $0
            }
            .disposed(by: disposeBag)

        viewModel.isVisible
            .bind { [weak self] in
                self?.isVisible = $0
            }
            .disposed(by: disposeBag)

        changeDate(.make(year: 2021, month: 1, day: 1))
        settings.statusItemDateStyleObserver.onNext(.short)
    }

    func changeDate(_ date: Date) {
        dateProvider.now = date
        dateChanged.onNext(())
        scheduler.advance(.seconds(1))
    }

    func setUp(showIcon: Bool, showDate: Bool) {
        settings.toggleIcon.onNext(showIcon)
        settings.toggleDate.onNext(showDate)
    }

    func setUp(showIcon: Bool, showDate: Bool, iconStyle: StatusItemIconStyle) {
        setUp(showIcon: showIcon, showDate: showDate)
        settings.statusItemIconStyleObserver.onNext(iconStyle)
    }

    @Test func testText_withDateChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        #expect(lastText == "2021-01-01")

        changeDate(.make(year: 2021, month: 1, day: 2))
        #expect(lastText == "2021-01-02")

        changeDate(.make(year: 2021, month: 2, day: 2))
        #expect(lastText == "2021-02-02")
    }

    @Test func testText_withLocaleChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        #expect(lastText == "2021-01-01")

        dateProvider.m_calendar.locale = Locale(identifier: "en")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        #expect(lastText == "1/1/21")
    }

    @Test func testStatusItemVisibility() {

        setUp(showIcon: true, showDate: true)
        #expect(isVisible == true)

        setUp(showIcon: true, showDate: false)
        #expect(isVisible == true)

        setUp(showIcon: false, showDate: true)
        #expect(isVisible == true)

        setUp(showIcon: false, showDate: false)
        #expect(isVisible == false)
    }

    @Test func testSaveStatusItemPreferredPosition() {

        let key = viewModel.preferredPositionKey
        let savedKey = viewModel.savedPreferredPositionKey

        localStorage.set(123, forKey: key)

        #expect(localStorage.integer(forKey: savedKey) == 123)
    }

    @Test func testRestoreStatusItemPreferredPosition_whenBecomingVisible() {

        let key = viewModel.preferredPositionKey
        let savedKey = viewModel.savedPreferredPositionKey

        setUp(showIcon: false, showDate: false)

        localStorage.set(123, forKey: savedKey)
        localStorage.removeObject(forKey: key)

        setUp(showIcon: true, showDate: false)

        #expect(localStorage.integer(forKey: key) == 123)
    }

    @Test func testIconVisibility() {

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.calendar?.style == .date)

        setUp(showIcon: true, showDate: true, iconStyle: .calendar)
        #expect(iconsAndText?.calendar?.style == .calendar)

        setUp(showIcon: true, showDate: true, iconStyle: .dayOfWeek)
        #expect(iconsAndText?.calendar?.style == .dayOfWeek)

        setUp(showIcon: true, showDate: false, iconStyle: .date)
        #expect(iconsAndText?.calendar?.style == .date)

        setUp(showIcon: true, showDate: false, iconStyle: .calendar)
        #expect(iconsAndText?.calendar?.style == .calendar)

        setUp(showIcon: true, showDate: false, iconStyle: .dayOfWeek)
        #expect(iconsAndText?.calendar?.style == .dayOfWeek)

        setUp(showIcon: false, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: true, iconStyle: .dayOfWeek)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: false, iconStyle: .date)
        #expect(iconsAndText?.calendar?.style == .date)

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        #expect(iconsAndText?.calendar?.style == .calendar)

        setUp(showIcon: false, showDate: false, iconStyle: .dayOfWeek)
        #expect(iconsAndText?.calendar?.style == .dayOfWeek)
    }

    @Test func testIconVisibility_withBirthday() {

        calendarService.changeEvents([.make(type: .birthday)])

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar != nil)

        setUp(showIcon: true, showDate: true, iconStyle: .calendar)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: true, showDate: false, iconStyle: .date)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar != nil)

        setUp(showIcon: true, showDate: false, iconStyle: .calendar)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: false, iconStyle: .date)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar == nil)
    }

    @Test func testBirthdayIconVisibility_withShowNextEventDisabled() {

        calendarService.changeEvents([.make(type: .birthday)])

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.birthday != nil)
        #expect(iconsAndText?.calendar != nil)

        settings.showEventStatusItemObserver.onNext(false)

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        #expect(iconsAndText?.birthday == nil)
        #expect(iconsAndText?.calendar != nil)
    }

    @Test func testDateVisibility() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        #expect(lastText == "2021-01-01")

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        #expect(lastText == "")
    }

    @Test func testDateStyle() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        settings.statusItemDateStyleObserver.onNext(.short)
        #expect(lastText == "1/1/21")

        settings.statusItemDateStyleObserver.onNext(.medium)
        #expect(lastText == "Jan 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.long)
        #expect(lastText == "January 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.full)
        #expect(lastText == "Friday, January 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.none)
        #expect(lastText == "???")

        settings.statusItemDateFormatObserver.onNext("E d MMM YY")
        #expect(lastText == "Fri 1 Jan 21")

        settings.statusItemDateStyleObserver.onNext(.short)
        #expect(lastText == "1/1/21")
    }

    @Test func testDateFormatWithTime() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm:ss")
        #expect(lastText == "00:00:00")

        dateProvider.add(1, .second)
        scheduler.advance(.seconds(1))
        #expect(lastText == "00:00:01")

        dateProvider.add(13, .hour)
        dateProvider.add(15, .minute)
        scheduler.advance(.seconds(1))
        #expect(lastText == "13:15:01")

        settings.statusItemDateFormatObserver.onNext("hh:mm a")
        #expect(lastText == "01:15 PM")
    }

    @Test func testDateFormatWithTimeZones() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("dd/MM/yyyy HH:mm@GMT+2'LT' | 'BR'HH:mm@GMT-3")

        #expect(lastText == "01/01/2021 02:00LT | BR21:00")

        settings.statusItemDateFormatObserver.onNext("dd/MM/yyyy HH:mm@GMT+2 'LT' | 'BR' HH:mm@GMT-3")

        #expect(lastText == "01/01/2021 02:00 LT | BR 21:00")
    }

    @Test func testDateFormatWithTimeZonesWithSeconds() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm:ss@GMT+2 | HH:mm:ss@GMT-3")

        #expect(lastText == "02:00:00 | 21:00:00")

        dateProvider.add(1, .second)
        scheduler.advance(.seconds(1))

        #expect(lastText == "02:00:01 | 21:00:01")
    }

    @Test func testDateFormatWithTimeZonesHalfHourOffset() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm@GMT+5:30 | HH:mm@GMT+9:30")

        #expect(lastText == "05:30 | 09:30")
    }

    @Test func testDateFormatWithTimeZonesQuarterHourOffset() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm@GMT+5:45 | HH:mm@GMT-3:15")

        #expect(lastText == "05:45 | 20:45")
    }

    @Test func testDateFormatWithMixedTimeZoneOffsets() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm@GMT+2 | HH:mm@GMT+5:30 | HH:mm@GMT-3")

        #expect(lastText == "02:00 | 05:30 | 21:00")
    }

    @Test func testBackground() {

        var image: NSImage?

        viewModel.image
            .bind { image = $0 }
            .disposed(by: disposeBag)

        scheduler.advance(.nanoseconds(1))
        #expect(image != nil)

        image = nil
        settings.toggleBackground.onNext(true)
        scheduler.advance(.nanoseconds(1))
        #expect(image != nil)

        image = nil
        settings.toggleBackground.onNext(false)
        scheduler.advance(.nanoseconds(1))
        #expect(image != nil)
    }
}
