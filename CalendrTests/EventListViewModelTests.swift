//
//  EventListViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 26/02/2021.
//

import XCTest
import RxSwift
@testable import Calendr

class EventListViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let eventsSubject = PublishSubject<[EventModel]>()

    let dateProvider = MockDateProvider()
    let workspaceProvider = MockWorkspaceProvider()
    let settings = MockEventSettings()

    lazy var viewModel = EventListViewModel(
        eventsObservable: eventsSubject,
        dateProvider: dateProvider,
        workspaceProvider: workspaceProvider,
        settings: settings
    )

    var eventViewModels: [EventViewModel]?

    override func setUp() {

        viewModel.asObservable()
            .bind { [weak self] in
                self?.eventViewModels = $0
            }
            .disposed(by: disposeBag)
    }

    func testEventListSorting() {

        let now = Date()

        let events: [EventModel] = [
            .make(start: now + 10, end: now + 100, title: "Event 1", isAllDay: false),
            .make(start: now + 10, end: now + 50, title: "Event 2", isAllDay: false),
            .make(start: now, end: now + 10, title: "All day 1", isAllDay: true),
            .make(start: now, end: now + 10, title: "Event 3", isAllDay: false),
            .make(start: now, end: now + 10, title: "All day 2", isAllDay: true)
        ]

        eventsSubject.onNext(events)

        XCTAssertEqual(eventViewModels?.map(\.title), [
            "All day 1", "All day 2", "Event 3", "Event 2", "Event 1"
        ])
    }
}
