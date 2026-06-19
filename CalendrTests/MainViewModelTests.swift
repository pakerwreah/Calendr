//
//  MainViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 19/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class MainViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let settings = MockCalendarSettings()
    let autoUpdater = MockAutoUpdater()
    let isAppActive = BehaviorSubject(value: true)
    let notificationCenter = NotificationCenter()
    let workspace = MockWorkspaceServiceProvider()

    lazy var viewModel = MainViewModel(
        dateProvider: dateProvider,
        settings: settings,
        autoUpdater: autoUpdater,
        isAppActive: isAppActive.asObservable(),
        notificationCenter: notificationCenter,
        workspace: workspace
    )

    override func setUp() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        dateProvider.now = .make(year: 2021, month: 1, day: 5)
    }

    func testCalendarDayChanged_resetsSelectedDateToCurrentDate() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        notificationCenter.post(name: .NSCalendarDayChanged, object: nil)

        XCTAssertEqual(viewModel.currentSelectedDate, dateProvider.now)
    }

    func testDidWake_resetsSelectedDateToCurrentDate() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        workspace.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)

        XCTAssertEqual(viewModel.currentSelectedDate, dateProvider.now)
    }

    func testViewDidDisappear_preservesSelectedDateWhenEnabled() {

        settings.togglePreserveSelectedDate.onNext(true)

        let selectedDate = Date.make(year: 2021, month: 1, day: 10)

        viewModel.selectDateObserver.onNext(selectedDate)

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        viewModel.viewDidDisappearObserver.onNext(())

        XCTAssertEqual(viewModel.currentSelectedDate, selectedDate)
    }

    func testSearchSuggestion_becomesVisibleWhenInputIsFocused() throws {

        var searchSuggestionText: String?
        var isSearchInputSuggestionHidden: Bool?

        viewModel.searchInputSuggestionText.bind {
            searchSuggestionText = $0
        }
        .disposed(by: disposeBag)

        viewModel.isSearchInputSuggestionHidden.bind {
            isSearchInputSuggestionHidden = $0
        }
        .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())
        viewModel.searchInputTextObserver.onNext("2021-01-10 lunch")

        XCTAssertEqual(isSearchInputSuggestionHidden, true)

        viewModel.searchInputFocusObserver.onNext(true)

        XCTAssertEqual(searchSuggestionText, "January 10, 2021")
        XCTAssertEqual(isSearchInputSuggestionHidden, false)
    }

    func testAcceptSearchSuggestion_updatesSelectedDateAndSearchText() throws {

        var searchInputText: String?

        viewModel.searchInputText.bind {
            searchInputText = $0
        }
        .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())
        viewModel.searchInputFocusObserver.onNext(true)
        viewModel.searchInputTextObserver.onNext("2021-01-10 lunch")
        viewModel.acceptSearchInputSuggestionObserver.onNext(())

        XCTAssertEqual(viewModel.currentSelectedDate, .make(year: 2021, month: 1, day: 10))
        XCTAssertEqual(searchInputText, "")
    }

    func testViewDidDisappear_resetsSearchInputWhenViewDisappear() {

        var searchInputText: String?
        var isSearchInputHidden: Bool?
        var isSearchInputSuggestionHidden: Bool?

        viewModel.searchInputText.bind {
            searchInputText = $0
        }
        .disposed(by: disposeBag)

        viewModel.isSearchInputHidden.bind {
            isSearchInputHidden = $0
        }
        .disposed(by: disposeBag)
        
        viewModel.isSearchInputSuggestionHidden.bind {
            isSearchInputSuggestionHidden = $0
        }
        .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())
        viewModel.searchInputTextObserver.onNext("2021-01-10 lunch")
        viewModel.viewDidDisappearObserver.onNext(())

        XCTAssertEqual(searchInputText, "")
        XCTAssertEqual(isSearchInputHidden, true)
        XCTAssertEqual(isSearchInputSuggestionHidden, true)
    }

    func testCreateButtonHidden_forPastDatesOnly() {

        var isCreateButtonHidden: Bool?

        viewModel.isCreateButtonHidden.bind {
            isCreateButtonHidden = $0
        }
        .disposed(by: disposeBag)

        XCTAssertEqual(isCreateButtonHidden, false)

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 4))
        XCTAssertEqual(isCreateButtonHidden, true)

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 5, hour: 8))
        XCTAssertEqual(isCreateButtonHidden, false)
    }

    func testDeeplink_updatesSelectedDateAndShowsMainPopover() throws {

        let mainPopoverExpectation = expectation(description: "Main Popover")

        viewModel.showMainPopover.bind {
            mainPopoverExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.deeplinkObserver.onNext(try XCTUnwrap(URL(string: "calendr://date/2021-01-20")))

        XCTAssertEqual(viewModel.currentSelectedDate, .make(year: 2021, month: 1, day: 20))

        waitForExpectations(timeout: 0.1)
    }

    func testUpdateAction_autoUpdaterNewVersionNotification_defaultAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.newVersion(.default))

        XCTAssertEqual(updateAction, .openSettings(.about))
    }

    func testUpdateAction_autoUpdaterNewVersionNotification_installAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.newVersion(.install))

        XCTAssertEqual(updateAction, .installUpdate)
    }

    func testUpdateAction_autoUpdaterUpdatedNotification_defaultAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.updated)

        XCTAssertEqual(updateAction, .openReleasePage)
    }

    func testKeyboardModifiers_resetsOnViewDidDisappear() {

        var lastModifiers: NSEvent.ModifierFlags?

        viewModel.keyboardModifiers
            .bind { lastModifiers = $0 }
            .disposed(by: disposeBag)

        viewModel.keyboardModifiersObserver.onNext([.command, .shift])
        XCTAssertEqual(lastModifiers, [.command, .shift])

        viewModel.viewDidDisappearObserver.onNext(())
        XCTAssertEqual(lastModifiers, [])
    }

    func testKeyboardModifiers_resetsWhenAppBecomesInactive() {

        var lastModifiers: NSEvent.ModifierFlags?

        viewModel.keyboardModifiers
            .bind { lastModifiers = $0 }
            .disposed(by: disposeBag)

        viewModel.keyboardModifiersObserver.onNext([.command, .shift])
        XCTAssertEqual(lastModifiers, [.command, .shift])

        isAppActive.onNext(false)
        XCTAssertEqual(lastModifiers, [])
    }

    func testOpenCalendarInDayView_opensDayViewInWorkspace() {

        let expectedDate = Date.make(year: 2021, month: 1, day: 10)
        var date: Date?
        var mode: CalendarViewMode?

        workspace.didOpenDate = { openedDate, openedMode in
            date = openedDate
            mode = openedMode
        }

        viewModel.openCalendarDateObserver.onNext(expectedDate)

        XCTAssertEqual(date, expectedDate)
        XCTAssertEqual(mode, .day)
    }

    func testOpenCalendar_opensPreferredViewInWorkspace() {

        let expectedDate = Date.make(year: 2021, month: 1, day: 10)
        var date: Date?
        var mode: CalendarViewMode?

        workspace.didOpenDate = { openedDate, openedMode in
            date = openedDate
            mode = openedMode
        }

        viewModel.selectDateObserver.onNext(expectedDate)
        viewModel.openCalendarObserver.onNext(())

        XCTAssertEqual(date, expectedDate)
        XCTAssertEqual(mode, .month)
    }

    func testCreateMenuItems_includesQuickRemindersForToday() {

        let items = viewModel.createMenuItems

        XCTAssertEqual(items.count, 7)
        XCTAssertEqual(items[0], .newEvent)
        XCTAssertEqual(items[1], .separator)

        guard case .quickReminder(_, let firstOffset) = items[2],
              case .quickReminder(_, let lastOffset) = items[6] else {
            return XCTFail("Expected quick reminder items")
        }

        XCTAssertEqual(firstOffset.minute, 5)
        XCTAssertEqual(lastOffset.day, 1)
    }

    func testCreateMenuItems_includesSingleReminderForOtherDates() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        XCTAssertEqual(viewModel.createMenuItems, [.newEvent, .newReminder])
    }
}
