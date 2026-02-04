//
//  StatusItemViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 07/02/21.
//

import XCTest
import RxSwift
@testable import Calendr

class StatusItemViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateChanged = PublishSubject<Void>()
    let calendarsSubject = BehaviorSubject<[String]>(value: [])

    let dateProvider = MockDateProvider()
    let screenProvider = MockScreenProvider()
    let calendarService = MockCalendarServiceProvider()
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
        notificationCenter: notificationCenter,
        scheduler: scheduler
    )

    var iconsAndText: StatusItemViewModel.IconsAndText?
    var lastText: String? { iconsAndText?.text }
    var isVisible: Bool?

    override func setUp() {

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

    func testText_withDateChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        XCTAssertEqual(lastText, "2021-01-01")

        changeDate(.make(year: 2021, month: 1, day: 2))
        XCTAssertEqual(lastText, "2021-01-02")

        changeDate(.make(year: 2021, month: 2, day: 2))
        XCTAssertEqual(lastText, "2021-02-02")
    }

    func testText_withLocaleChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        XCTAssertEqual(lastText, "2021-01-01")

        dateProvider.m_calendar.locale = Locale(identifier: "en")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(lastText, "1/1/21")
    }

    func testStatusItemVisibility() {

        setUp(showIcon: true, showDate: true)
        XCTAssertEqual(isVisible, true)

        setUp(showIcon: true, showDate: false)
        XCTAssertEqual(isVisible, true)

        setUp(showIcon: false, showDate: true)
        XCTAssertEqual(isVisible, true)

        setUp(showIcon: false, showDate: false)
        XCTAssertEqual(isVisible, false)
    }

    func testIconVisibility() {

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        XCTAssertEqual(iconsAndText?.calendar?.style, .date)

        setUp(showIcon: true, showDate: true, iconStyle: .calendar)
        XCTAssertEqual(iconsAndText?.calendar?.style, .calendar)

        setUp(showIcon: true, showDate: true, iconStyle: .dayOfWeek)
        XCTAssertEqual(iconsAndText?.calendar?.style, .dayOfWeek)

        setUp(showIcon: true, showDate: false, iconStyle: .date)
        XCTAssertEqual(iconsAndText?.calendar?.style, .date)

        setUp(showIcon: true, showDate: false, iconStyle: .calendar)
        XCTAssertEqual(iconsAndText?.calendar?.style, .calendar)

        setUp(showIcon: true, showDate: false, iconStyle: .dayOfWeek)
        XCTAssertEqual(iconsAndText?.calendar?.style, .dayOfWeek)

        setUp(showIcon: false, showDate: true, iconStyle: .date)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: true, iconStyle: .dayOfWeek)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: false, iconStyle: .date)
        XCTAssertEqual(iconsAndText?.calendar?.style, .date)

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        XCTAssertEqual(iconsAndText?.calendar?.style, .calendar)

        setUp(showIcon: false, showDate: false, iconStyle: .dayOfWeek)
        XCTAssertEqual(iconsAndText?.calendar?.style, .dayOfWeek)
    }

    func testIconVisibility_withBirthday() {

        calendarService.changeEvents([.make(type: .birthday)])

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNotNil(iconsAndText?.calendar)

        setUp(showIcon: true, showDate: true, iconStyle: .calendar)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: true, showDate: false, iconStyle: .date)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNotNil(iconsAndText?.calendar)

        setUp(showIcon: true, showDate: false, iconStyle: .calendar)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: true, iconStyle: .date)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: false, iconStyle: .date)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNil(iconsAndText?.calendar)
    }

    func testBirthdayIconVisibility_withShowNextEventDisabled() {

        calendarService.changeEvents([.make(type: .birthday)])

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        XCTAssertNotNil(iconsAndText?.birthday)
        XCTAssertNotNil(iconsAndText?.calendar)

        settings.showEventStatusItemObserver.onNext(false)

        setUp(showIcon: true, showDate: true, iconStyle: .date)
        XCTAssertNil(iconsAndText?.birthday)
        XCTAssertNotNil(iconsAndText?.calendar)
    }

    func testDateVisibility() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)
        XCTAssertEqual(lastText, "2021-01-01")

        setUp(showIcon: false, showDate: false, iconStyle: .calendar)
        XCTAssertEqual(lastText, "")
    }

    func testDateStyle() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        settings.statusItemDateStyleObserver.onNext(.short)
        XCTAssertEqual(lastText, "1/1/21")

        settings.statusItemDateStyleObserver.onNext(.medium)
        XCTAssertEqual(lastText, "Jan 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.long)
        XCTAssertEqual(lastText, "January 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.full)
        XCTAssertEqual(lastText, "Friday, January 1, 2021")

        settings.statusItemDateStyleObserver.onNext(.none)
        XCTAssertEqual(lastText, "???")

        settings.statusItemDateFormatObserver.onNext("E d MMM YY")
        XCTAssertEqual(lastText, "Fri 1 Jan 21")

        settings.statusItemDateStyleObserver.onNext(.short)
        XCTAssertEqual(lastText, "1/1/21")
    }

    func testDateFormatWithTime() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("HH:mm:ss")
        XCTAssertEqual(lastText, "00:00:00")

        dateProvider.add(1, .second)
        scheduler.advance(.seconds(1))
        XCTAssertEqual(lastText, "00:00:01")

        dateProvider.add(13, .hour)
        dateProvider.add(15, .minute)
        scheduler.advance(.seconds(1))
        XCTAssertEqual(lastText, "13:15:01")

        settings.statusItemDateFormatObserver.onNext("hh:mm a")
        XCTAssertEqual(lastText, "01:15 PM")
    }

    func testDateFormatWithTimeZones() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("dd/MM/yyyy HH:mm@GMT+2'LT' | 'BR'HH:mm@GMT-3")

        XCTAssertEqual(lastText, "01/01/2021 02:00LT | BR21:00")

        settings.statusItemDateFormatObserver.onNext("dd/MM/yyyy HH:mm@GMT+2 'LT' | 'BR' HH:mm@GMT-3")

        XCTAssertEqual(lastText, "01/01/2021 02:00 LT | BR 21:00")
    }

    func testDateFormatWithTimeZonesWithSeconds() {

        setUp(showIcon: false, showDate: true, iconStyle: .calendar)

        settings.statusItemDateStyleObserver.onNext(.none)
        settings.statusItemDateFormatObserver.onNext("dd/MM/yyyy HH:mm:ss@GMT+2'LT' | HH:mm:ss@GMT-3'BR'")

        XCTAssertEqual(lastText, "01/01/2021 02:00:00LT | 21:00:00BR")

        dateProvider.add(1, .second)
        scheduler.advance(.seconds(1))

        XCTAssertEqual(lastText, "01/01/2021 02:00:01LT | 21:00:01BR")
    }

    func testBackground() {

        var image: NSImage?

        viewModel.image
            .bind { image = $0 }
            .disposed(by: disposeBag)

        scheduler.advance(.nanoseconds(1))
        XCTAssertNotNil(image)

        image = nil
        settings.toggleBackground.onNext(true)
        scheduler.advance(.nanoseconds(1))
        XCTAssertNotNil(image)

        image = nil
        settings.toggleBackground.onNext(false)
        scheduler.advance(.nanoseconds(1))
        XCTAssertNotNil(image)
    }
}
