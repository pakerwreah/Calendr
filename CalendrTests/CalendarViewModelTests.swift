//
//  CalendarViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 09/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class CalendarViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()
    let dateSubject = PublishSubject<Date>()
    let hoverSubject = PublishSubject<Date?>()

    let calendarServiceProvider = MockCalendarServiceProvider()

    lazy var viewModel = CalendarViewModel(dateObservable: dateSubject,
                                           hoverObservable: hoverSubject,
                                           calendarService: calendarServiceProvider)

    var values = [[CalendarCellViewModel]]()

    override func setUp() {
        viewModel
            .asObservable()
            .bind { [weak self] in
                self?.values.append($0)
            }
            .disposed(by: disposeBag)

        dateSubject.onNext(.make(year: 2021, month: 1, day: 1))
    }

    func testDateSpan() {

        guard let cellViewModels = values.last else {
            return XCTFail()
        }

        XCTAssertEqual(cellViewModels.count, 42)
        XCTAssertEqual(cellViewModels.first.map(\.date), .make(year: 2020, month: 12, day: 27))
        XCTAssertEqual(cellViewModels.last.map(\.date), .make(year: 2021, month: 2, day: 6))
    }

    func testHoverDistinctly() {

        (1...5).map {
            Date.make(year: 2021, month: 1, day: $0)
        }
        .forEach { date in
            hoverSubject.onNext(date)

            guard let hovered = values.last?.filter(\.isHovered) else {
                return XCTFail()
            }

            XCTAssertEqual(hovered.count, 1)
            XCTAssertEqual(hovered.first.map(\.date), date)
        }

    }

    func testUnhover() {

        hoverSubject.onNext(.make(year: 2021, month: 1, day: 1))
        XCTAssert(values.last?.filter(\.isHovered).isEmpty == false)

        hoverSubject.onNext(nil)
        XCTAssert(values.last?.filter(\.isHovered).isEmpty == true)
    }

}

class MockCalendarServiceProvider: CalendarServiceProviding {

    var calendars: [CalendarModel] = []
    var events: [EventModel] = []

    let (changeObservable, changeObserver) = PublishSubject<Void>.pipe()

    func events(from start: Date, to end: Date) -> [EventModel] {
        return events
    }
}
