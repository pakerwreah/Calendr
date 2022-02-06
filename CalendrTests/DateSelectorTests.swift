//
//  DateSelectorTests.swift
//  CalendrTests
//
//  Created by Paker on 01/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class DateSelectorTests: XCTestCase {

    let disposeBag = DisposeBag()

    let initial = PublishSubject<Date>()
    let selected = PublishSubject<Date>()
    let reset = PublishSubject<Void>()
    let prevDay = PublishSubject<Void>()
    let nextDay = PublishSubject<Void>()
    let prevWeek = PublishSubject<Void>()
    let nextWeek = PublishSubject<Void>()
    let prevMonth = PublishSubject<Void>()
    let nextMonth = PublishSubject<Void>()

    var values = [String]()

    override func setUp() {
        // 🔨 Prevent reentrancy anomaly warning
        let scheduler = HistoricalScheduler()

        let advance = { (_: Any) in scheduler.advance(.seconds(1)) }

        let selector = DateSelector(
            calendar: .gregorian,
            initial: initial.do(onNext: advance),
            selected: selected,
            reset: reset.do(onNext: advance),
            prevDay: prevDay.do(onNext: advance),
            nextDay: nextDay.do(onNext: advance),
            prevWeek: prevWeek.do(onNext: advance),
            nextWeek: nextWeek.do(onNext: advance),
            prevMonth: prevMonth.do(onNext: advance),
            nextMonth: nextMonth.do(onNext: advance)
        )

        selector
            .asObservable()
            .observe(on: scheduler)
            .bind(to: selected)
            .disposed(by: disposeBag)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate

        selector
            .asObservable()
            .map(formatter.string(from:))
            .bind { [weak self] in
                self?.values.append($0)
            }
            .disposed(by: disposeBag)

        initial.onNext(.make(year: 2021, month: 1, day: 1))
    }

    func testInitial() {
        initial.onNext(.make(year: 2025, month: 1, day: 1))

        XCTAssertEqual(values.last, "2025-01-01")
    }

    func testSelect() {
        selected.onNext(.make(year: 2025, month: 1, day: 1))

        XCTAssertEqual(values.last, "2025-01-01")
    }

    func testReset() {
        selected.onNext(.make(year: 2025, month: 1, day: 1))
        reset.onNext(())

        XCTAssertEqual(values, ["2021-01-01", "2025-01-01", "2021-01-01"])
    }

    func testDistinct() {
        nextDay.onNext(())
        initial.onNext(.make(year: 2021, month: 1, day: 2))
        selected.onNext(.make(year: 2021, month: 1, day: 2))
        reset.onNext(())

        XCTAssertEqual(values, ["2021-01-01", "2021-01-02"])
    }

    func testPrevDay() {
        prevDay.onNext(())

        XCTAssertEqual(values.last, "2020-12-31")
    }

    func testNextDay() {
        nextDay.onNext(())

        XCTAssertEqual(values.last, "2021-01-02")
    }

    func testPrevWeek() {
        prevWeek.onNext(())

        XCTAssertEqual(values.last, "2020-12-25")
    }

    func testNextWeek() {
        nextWeek.onNext(())

        XCTAssertEqual(values.last, "2021-01-08")
    }

    func testPrevMonth() {
        prevMonth.onNext(())

        XCTAssertEqual(values.last, "2020-12-01")
    }

    func testNextMonth() {
        nextMonth.onNext(())

        XCTAssertEqual(values.last, "2021-02-01")
    }

    func testSequence() {
        [
            prevDay,
            nextDay,
            prevWeek,
            nextWeek,
            prevMonth,
            nextMonth
        ]
        .forEach {
            $0.onNext(())
        }

        XCTAssertEqual(values, [
            "2021-01-01", // initial
            "2020-12-31", // prevDay
            "2021-01-01", // nextDay
            "2020-12-25", // prevWeek
            "2021-01-01", // nextWeek
            "2020-12-01", // prevMonth
            "2021-01-01", // nextMonth
        ])
    }

}
