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

    let dateSubject = PublishSubject<Date>()

    let dateProvider = MockDateProvider()
    let settings = MockStatusItemSettings()

    let notificationCenter = NotificationCenter()

    lazy var viewModel = StatusItemViewModel(
        dateObservable: dateSubject,
        settings: settings,
        dateProvider: dateProvider,
        notificationCenter: notificationCenter
    )

    var lastValue: String?

    override func setUp() {

        viewModel.text
            .bind { [weak self] in
                self?.lastValue = $0.string
            }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
        settings.dateStyleObserver.onNext(.short)
    }

    func setUp(showIcon: Bool, showDate: Bool) {
        settings.toggleIcon.onNext(showIcon)
        settings.toggleDate.onNext(showDate)
    }

    func testText_withDateChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true)

        XCTAssertEqual(lastValue, "2021-01-01")

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        XCTAssertEqual(lastValue, "2021-01-02")

        dateSubject.onNext(.make(year: 2021, month: 2, day: 2))
        XCTAssertEqual(lastValue, "2021-02-02")
    }

    func testText_withLocaleChange_shouldUpdateText() {

        setUp(showIcon: false, showDate: true)

        XCTAssertEqual(lastValue, "2021-01-01")

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(lastValue, "1/1/21")
    }

    func testIconVisibility() {

        setUp(showIcon: true, showDate: true)
        XCTAssertEqual(lastValue?.first, "📅")

        setUp(showIcon: false, showDate: true)
        XCTAssertNotEqual(lastValue?.first, "📅")
    }

    func testDateVisibility() {

        setUp(showIcon: true, showDate: true)
        XCTAssertEqual(lastValue, "📅  2021-01-01")

        setUp(showIcon: true, showDate: false)
        XCTAssertEqual(lastValue, "📅")
    }

    func testDateStyle() {

        setUp(showIcon: false, showDate: true)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        settings.dateStyleObserver.onNext(.short)
        XCTAssertEqual(lastValue, "1/1/21")

        settings.dateStyleObserver.onNext(.medium)
        XCTAssertEqual(lastValue, "Jan 1, 2021")

        settings.dateStyleObserver.onNext(.long)
        XCTAssertEqual(lastValue, "January 1, 2021")

        settings.dateStyleObserver.onNext(.full)
        XCTAssertEqual(lastValue, "Friday, January 1, 2021")
    }
}
