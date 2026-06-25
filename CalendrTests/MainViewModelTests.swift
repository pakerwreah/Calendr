//
//  MainViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 19/06/2026.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class MainViewModelTests {

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

    init() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        dateProvider.now = .make(year: 2021, month: 1, day: 5)
    }

    @Test func testCalendarDayChanged_resetsSelectedDateToCurrentDate() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        notificationCenter.post(name: .NSCalendarDayChanged, object: nil)

        #expect(viewModel.currentSelectedDate == dateProvider.now)
    }

    @Test func testDidWake_resetsSelectedDateToCurrentDate() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        workspace.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)

        #expect(viewModel.currentSelectedDate == dateProvider.now)
    }

    @Test func testViewDidDisappear_preservesSelectedDateWhenEnabled() {

        settings.togglePreserveSelectedDate.onNext(true)

        let selectedDate = Date.make(year: 2021, month: 1, day: 10)

        viewModel.selectDateObserver.onNext(selectedDate)

        dateProvider.now = .make(year: 2021, month: 1, day: 20)
        viewModel.viewDidDisappearObserver.onNext(())

        #expect(viewModel.currentSelectedDate == selectedDate)
    }

    @Test func testSearchSuggestion_becomesVisibleWhenInputIsFocused() throws {

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

        #expect(isSearchInputSuggestionHidden == true)

        viewModel.searchInputFocusObserver.onNext(true)

        #expect(searchSuggestionText == "January 10, 2021")
        #expect(isSearchInputSuggestionHidden == false)
    }

    @Test func testAcceptSearchSuggestion_updatesSelectedDateAndSearchText() throws {

        var searchInputText: String?

        viewModel.searchInputText.bind {
            searchInputText = $0
        }
        .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())
        viewModel.searchInputFocusObserver.onNext(true)
        viewModel.searchInputTextObserver.onNext("2021-01-10 lunch")
        viewModel.acceptSearchInputSuggestionObserver.onNext(())

        #expect(viewModel.currentSelectedDate == .make(year: 2021, month: 1, day: 10))
        #expect(searchInputText == "")
    }

    @Test func testViewDidDisappear_resetsSearchInputWhenViewDisappear() {

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

        #expect(searchInputText == "")
        #expect(isSearchInputHidden == true)
        #expect(isSearchInputSuggestionHidden == true)
    }

    @Test func testCreateButtonHidden_forPastDatesOnly() {

        var isCreateButtonHidden: Bool?

        viewModel.isCreateButtonHidden.bind {
            isCreateButtonHidden = $0
        }
        .disposed(by: disposeBag)

        #expect(isCreateButtonHidden == false)

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 4))
        #expect(isCreateButtonHidden == true)

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 5, hour: 8))
        #expect(isCreateButtonHidden == false)
    }

    @Test func testDeeplink_updatesSelectedDateAndShowsMainPopover() async throws {

        let mainPopoverExpectation = expectation(description: "Main Popover")

        viewModel.showMainPopover.bind {
            mainPopoverExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.deeplinkObserver.onNext(try #require(URL(string: "calendr://date/2021-01-20")))

        #expect(viewModel.currentSelectedDate == .make(year: 2021, month: 1, day: 20))

        await fulfillment(of: [mainPopoverExpectation])
    }

    @Test func testUpdateAction_autoUpdaterNewVersionNotification_defaultAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.newVersion(.default))

        #expect(updateAction == .openSettings(.about))
    }

    @Test func testUpdateAction_autoUpdaterNewVersionNotification_installAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.newVersion(.install))

        #expect(updateAction == .installUpdate)
    }

    @Test func testUpdateAction_autoUpdaterUpdatedNotification_defaultAction() {

        var updateAction: MainViewModel.UpdateAction?

        viewModel.updateAction.bind {
            updateAction = $0
        }
        .disposed(by: disposeBag)

        autoUpdater.notificationTapObserver.onNext(.updated)

        #expect(updateAction == .openReleasePage)
    }

    @Test func testKeyboardModifiers_resetsOnViewDidDisappear() {

        var lastModifiers: NSEvent.ModifierFlags?

        viewModel.keyboardModifiers
            .bind { lastModifiers = $0 }
            .disposed(by: disposeBag)

        viewModel.keyboardModifiersObserver.onNext([.command, .shift])
        #expect(lastModifiers == [.command, .shift])

        viewModel.viewDidDisappearObserver.onNext(())
        #expect(lastModifiers == [])
    }

    @Test func testKeyboardModifiers_resetsWhenAppBecomesInactive() {

        var lastModifiers: NSEvent.ModifierFlags?

        viewModel.keyboardModifiers
            .bind { lastModifiers = $0 }
            .disposed(by: disposeBag)

        viewModel.keyboardModifiersObserver.onNext([.command, .shift])
        #expect(lastModifiers == [.command, .shift])

        isAppActive.onNext(false)
        #expect(lastModifiers == [])
    }

    @Test func testOpenCalendarInDayView_opensDayViewInWorkspace() {

        let expectedDate = Date.make(year: 2021, month: 1, day: 10)
        var date: Date?
        var mode: CalendarViewMode?

        workspace.didOpenDate = { openedDate, openedMode in
            date = openedDate
            mode = openedMode
        }

        viewModel.openCalendarDateObserver.onNext(expectedDate)

        #expect(date == expectedDate)
        #expect(mode == .day)
    }

    @Test func testOpenCalendar_opensPreferredViewInWorkspace() {

        let expectedDate = Date.make(year: 2021, month: 1, day: 10)
        var date: Date?
        var mode: CalendarViewMode?

        workspace.didOpenDate = { openedDate, openedMode in
            date = openedDate
            mode = openedMode
        }

        viewModel.selectDateObserver.onNext(expectedDate)
        viewModel.openCalendarObserver.onNext(())

        #expect(date == expectedDate)
        #expect(mode == .month)
    }

    @Test func testCreateMenuItems_includesQuickRemindersForToday() {

        let items = viewModel.createMenuItems

        #expect(items.count == 7)
        #expect(items[0] == .newEvent)
        #expect(items[1] == .separator)

        guard case .quickReminder(_, let firstOffset) = items[2],
              case .quickReminder(_, let lastOffset) = items[6] else {
            Issue.record("Expected quick reminder items")
            return
        }

        #expect(firstOffset.minute == 5)
        #expect(lastOffset.day == 1)
    }

    @Test func testCreateMenuItems_includesSingleReminderForOtherDates() {

        viewModel.selectDateObserver.onNext(.make(year: 2021, month: 1, day: 10))

        #expect(viewModel.createMenuItems == [.newEvent, .newReminder])
    }
}
