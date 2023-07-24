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

    let notificationCenter = NotificationCenter()

    lazy var viewModel = StatusItemViewModel(
        dateChanged: dateChanged,
        nextEventCalendars: calendarsSubject,
        settings: settings,
        dateProvider: dateProvider,
        screenProvider: screenProvider,
        calendarService: calendarService,
        notificationCenter: notificationCenter
    )

    var iconsAndText: ([NSImage], String)?
    var iconsCount: Int { iconsAndText?.0.count ?? 0 }
    var lastText: String? { iconsAndText?.1 }

    override func setUp() {

        viewModel.iconsAndText
            .bind { [weak self] in
                self?.iconsAndText = $0
            }
            .disposed(by: disposeBag)

        changeDate(.make(year: 2021, month: 1, day: 1))
        settings.dateStyleObserver.onNext(.short)
    }

    func changeDate(_ date: Date) {
        dateProvider.now = date
        dateChanged.onNext(())
    }

    func setUp(showIcon: Bool, showDate: Bool, showIconDate: Bool) {
        settings.toggleIcon.onNext(showIcon)
        settings.toggleDate.onNext(showDate)
        settings.toggleIconDate.onNext(showIconDate)
    }

    func testText_withDateChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, showIconDate: false)

        XCTAssertEqual(lastText, "2021-01-01")

        changeDate(.make(year: 2021, month: 1, day: 2))
        XCTAssertEqual(lastText, "2021-01-02")

        changeDate(.make(year: 2021, month: 2, day: 2))
        XCTAssertEqual(lastText, "2021-02-02")
    }

    func testText_withLocaleChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true, showIconDate: false)

        XCTAssertEqual(lastText, "2021-01-01")

        dateProvider.m_calendar.locale = Locale(identifier: "en")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(lastText, "1/1/21")
    }

    func testIconVisibility() {

        setUp(showIcon: true, showDate: true, showIconDate: true)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: true, showDate: true, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: true, showDate: false, showIconDate: true)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: true, showDate: false, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: true, showIconDate: true)
        XCTAssertEqual(iconsCount, 0)

        setUp(showIcon: false, showDate: true, showIconDate: false)
        XCTAssertEqual(iconsCount, 0)

        setUp(showIcon: false, showDate: false, showIconDate: true)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: false, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)
    }

    func testIconVisibility_withBirthday() {

        calendarService.changeEvents([.make(type: .birthday)])

        setUp(showIcon: true, showDate: true, showIconDate: true)
        XCTAssertEqual(iconsCount, 2)

        setUp(showIcon: true, showDate: true, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: true, showDate: false, showIconDate: true)
        XCTAssertEqual(iconsCount, 2)

        setUp(showIcon: true, showDate: false, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: true, showIconDate: true)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: true, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: false, showIconDate: true)
        XCTAssertEqual(iconsCount, 1)

        setUp(showIcon: false, showDate: false, showIconDate: false)
        XCTAssertEqual(iconsCount, 1)
    }

    func testDateVisibility() {

        setUp(showIcon: false, showDate: true, showIconDate: false)
        XCTAssertEqual(lastText, "2021-01-01")

        setUp(showIcon: false, showDate: false, showIconDate: false)
        XCTAssertEqual(lastText, "")
    }

    func testDateStyle() {

        setUp(showIcon: false, showDate: true, showIconDate: false)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        settings.dateStyleObserver.onNext(.short)
        XCTAssertEqual(lastText, "1/1/21")

        settings.dateStyleObserver.onNext(.medium)
        XCTAssertEqual(lastText, "Jan 1, 2021")

        settings.dateStyleObserver.onNext(.long)
        XCTAssertEqual(lastText, "January 1, 2021")

        settings.dateStyleObserver.onNext(.full)
        XCTAssertEqual(lastText, "Friday, January 1, 2021")

        settings.dateStyleObserver.onNext(.none)
        XCTAssertEqual(lastText, "???")

        settings.dateFormatObserver.onNext("E d MMM YY")
        XCTAssertEqual(lastText, "Fri 1 Jan 21")

        settings.dateStyleObserver.onNext(.short)
        XCTAssertEqual(lastText, "1/1/21")
    }

    func testBackground() {

        var image: NSImage?

        viewModel.image
            .bind { image = $0 }
            .disposed(by: disposeBag)

        XCTAssertNotNil(image)

        image = nil
        settings.toggleBackground.onNext(true)
        XCTAssertNotNil(image)

        image = nil
        settings.toggleBackground.onNext(false)
        XCTAssertNotNil(image)
    }
}
