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

    var lastAttributed: NSAttributedString?
    var lastValue: String? { lastAttributed?.string }

    override func setUp() {

        viewModel.text
            .bind { [weak self] in
                self?.lastAttributed = $0
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

        dateProvider.m_calendar.locale = Locale(identifier: "en")
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(lastValue, "1/1/21")
    }

    func testIconVisibility() {

        setUp(showIcon: true, showDate: true)
        XCTAssertEqual(lastAttributed?.containsAttachments, true)

        setUp(showIcon: false, showDate: true)
        XCTAssertEqual(lastAttributed?.containsAttachments, false)
    }

    func testDateVisibility() {

        setUp(showIcon: false, showDate: true)
        XCTAssertEqual(lastValue, "2021-01-01")

        setUp(showIcon: false, showDate: false)
        XCTAssertEqual(lastValue, "")
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
