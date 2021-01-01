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

    private let initial = BehaviorSubject<Date>(value: .make(year: 2021, month: 1, day: 1))
    private let reset = PublishSubject<Void>()
    private let prevDay = PublishSubject<Void>()
    private let nextDay = PublishSubject<Void>()
    private let prevWeek = PublishSubject<Void>()
    private let nextWeek = PublishSubject<Void>()
    private let prevMonth = PublishSubject<Void>()
    private let nextMonth = PublishSubject<Void>()

    private lazy var observer = testScheduler.createObserver(String.self)

    private lazy var selector =
        DateSelector(
            initial: initial,
            reset: reset,
            prevDay: prevDay,
            nextDay: nextDay,
            prevWeek: prevWeek,
            nextWeek: nextWeek,
            prevMonth: prevMonth,
            nextMonth: nextMonth
        )
        .asObservable()

    override func setUp() {
        selector
            .map(formatter.string(from:))
            .bind(to: observer)
            .disposed(by: disposeBag)
    }

    func testReset() {
        reset.onNext(())

        XCTAssertEqual(observer.values.last, formatter.string(from: Date()))
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
        selector
            .bind(to: initial)
            .disposed(by: disposeBag)

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
