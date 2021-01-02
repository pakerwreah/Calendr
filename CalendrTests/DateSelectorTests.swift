//
//  DateSelectorTests.swift
//  CalendrTests
//
//  Created by Paker on 01/01/21.
//

import XCTest
import RxSwift
import RxTest
@testable import Calendr

class DateSelectorTests: XCTestCase {

    private let testScheduler = TestScheduler()
    private let disposeBag = DisposeBag()

    private let formatter = DateFormatter(format: "yyyy-MM-dd")

    private let initial = PublishSubject<Date>()
    private let selected = PublishSubject<Date>()
    private let reset = PublishSubject<Void>()
    private let prevDay = PublishSubject<Void>()
    private let nextDay = PublishSubject<Void>()
    private let prevWeek = PublishSubject<Void>()
    private let nextWeek = PublishSubject<Void>()
    private let prevMonth = PublishSubject<Void>()
    private let nextMonth = PublishSubject<Void>()

    private lazy var observer = testScheduler.createObserver(String.self)

    override func setUp() {
        let selector = DateSelector(
            initial: initial,
            selected: selected,
            reset: reset,
            prevDay: prevDay,
            nextDay: nextDay,
            prevWeek: prevWeek,
            nextWeek: nextWeek,
            prevMonth: prevMonth,
            nextMonth: nextMonth
        )

        selector
            .asObservable()
            .bind(to: selected)
            .disposed(by: disposeBag)

        selector
            .asObservable()
            .map(formatter.string(from:))
            .bind(to: observer)
            .disposed(by: disposeBag)

        initial.onNext(.make(year: 2021, month: 1, day: 1))
    }

    func testInitial() {
        initial.onNext(.make(year: 2025, month: 1, day: 1))

        XCTAssertEqual(observer.values.last, "2025-01-01")
    }

    func testReset() {
        nextDay.onNext(())
        reset.onNext(())

        XCTAssertEqual(observer.values, ["2021-01-01", "2021-01-02", "2021-01-01"])
    }

    func testDistinct() {
        nextDay.onNext(())
        initial.onNext(.make(year: 2021, month: 1, day: 2))
        reset.onNext(())

        XCTAssertEqual(observer.values, ["2021-01-01", "2021-01-02"])
    }

    func testPrevDay() {
        prevDay.onNext(())

        XCTAssertEqual(observer.values.last, "2020-12-31")
    }

    func testNextDay() {
        nextDay.onNext(())

        XCTAssertEqual(observer.values.last, "2021-01-02")
    }

    func testPrevWeek() {
        prevWeek.onNext(())

        XCTAssertEqual(observer.values.last, "2020-12-25")
    }

    func testNextWeek() {
        nextWeek.onNext(())

        XCTAssertEqual(observer.values.last, "2021-01-08")
    }

    func testPrevMonth() {
        prevMonth.onNext(())

        XCTAssertEqual(observer.values.last, "2020-12-01")
    }

    func testNextMonth() {
        nextMonth.onNext(())

        XCTAssertEqual(observer.values.last, "2021-02-01")
    }

    func testAll() {
        [
            prevDay,
            nextDay,
            prevWeek,
            nextWeek,
            prevMonth,
            nextMonth
        ]
        .forEach {
            let previous = observer.values.last

            $0.onNext(())

            let current = observer.values.last

            XCTAssertNotEqual(current, previous)
        }

        XCTAssertEqual(observer.values.last, "2021-01-01")
    }

}
