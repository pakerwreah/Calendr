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
        // ⚠️ Reentrancy anomaly was detected. ¯\_(ツ)_/¯
        // Normally we only need to .observeOn(MainScheduler.asyncInstance)
        // but since we're testing, we need to sync the flow to get the output
        // It still works without this "fix", but I don't feel comfortable with the warning

        let dispatchGroup = DispatchGroup()
        let wait = { (_: Any) in dispatchGroup.wait() }

        let selector = DateSelector(
            initial: initial.do(onNext: wait),
            selected: selected,
            reset: reset.do(onNext: wait),
            prevDay: prevDay.do(onNext: wait),
            nextDay: nextDay.do(onNext: wait),
            prevWeek: prevWeek.do(onNext: wait),
            nextWeek: nextWeek.do(onNext: wait),
            prevMonth: prevMonth.do(onNext: wait),
            nextMonth: nextMonth.do(onNext: wait)
        )

        selector
            .asObservable()
            .do(onNext: { _ in dispatchGroup.enter() })
            .delay(.milliseconds(1), scheduler: SerialDispatchQueueScheduler(qos: .default))
            .do(afterNext: { _ in dispatchGroup.leave() })
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

    func testSelect() {
        selected.onNext(.make(year: 2025, month: 1, day: 1))

        XCTAssertEqual(observer.values.last, "2025-01-01")
    }

    func testReset() {
        selected.onNext(.make(year: 2025, month: 1, day: 1))
        reset.onNext(())

        XCTAssertEqual(observer.values, ["2021-01-01", "2025-01-01", "2021-01-01"])
    }

    func testDistinct() {
        nextDay.onNext(())
        initial.onNext(.make(year: 2021, month: 1, day: 2))
        selected.onNext(.make(year: 2021, month: 1, day: 2))
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

        XCTAssertEqual(observer.values.count, 7)
        XCTAssertEqual(observer.values.last, "2021-01-01")
    }

}
