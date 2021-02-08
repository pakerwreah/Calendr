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

    lazy var viewModel = StatusItemViewModel(
        dateObservable: dateSubject,
        settings: settings,
        locale: Locale(identifier: "en_US")
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

    func testIconVisibility() {

        settings.onNext(.init(showIcon: true, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue?.first, "\u{1f4c5}")

        settings.onNext(.init(showIcon: false, showDate: true, dateStyle: .short))
        XCTAssertNotEqual(lastValue?.first, "\u{1f4c5}")
    }

    func testDateVisibility() {

        settings.onNext(.init(showIcon: true, showDate: true, dateStyle: .short))
        XCTAssertEqual(lastValue, "\u{1f4c5}  1/1/21")

        settings.onNext(.init(showIcon: true, showDate: false, dateStyle: .short))
        XCTAssertEqual(lastValue, "\u{1f4c5}")
    }

    func testDateStyle() {

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
