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
    let settings = PublishSubject<StatusItemSettings>()

    let dateProvider = MockDateProvider()

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
    }

    func testText_withDateChange_shouldUpdateText() {

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue, "2021-01-01")

        dateSubject.onNext(.make(year: 2021, month: 1, day: 2))
        XCTAssertEqual(lastValue, "2021-01-02")

        dateSubject.onNext(.make(year: 2021, month: 2, day: 2))
        XCTAssertEqual(lastValue, "2021-02-02")
    }

    func testText_withLocaleChange_shouldUpdateText() {

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue, "2021-01-01")

        dateProvider.m_calendar.locale = Locale(identifier: "en")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(lastValue, "1/1/21")
    }

    func testIconVisibility() {

        settings.onNext(.init(showIcon: true, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue?.first, "📅")

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .short))
        XCTAssertNotEqual(lastValue?.first, "📅")
    }

    func testDateVisibility() {

        settings.onNext(.init(showIcon: true, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue, "📅  2021-01-01")

        settings.onNext(.init(showIcon: true, showDate: false, dateStyle: .short))
        XCTAssertEqual(lastValue, "📅")
    }

    func testDateStyle() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue, "1/1/21")

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .medium))
        XCTAssertEqual(lastValue, "Jan 1, 2021")

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .long))
        XCTAssertEqual(lastValue, "January 1, 2021")

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .full))
        XCTAssertEqual(lastValue, "Friday, January 1, 2021")
    }
}
