//
//  MainViewModelShortcutsTests.swift
//  Calendr
//
//  Created by Paker on 04/10/2026.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class MainViewModelShortcutsTests {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let settings = MockMainViewSettings()
    let autoUpdater = MockAutoUpdater()
    let isAppActive = BehaviorSubject(value: true)
    let hasPendingInvites = BehaviorSubject(value: false)
    let notificationCenter = NotificationCenter()
    let workspace = MockWorkspaceServiceProvider()
    let launchServices = MockLaunchServiceProvider()

    lazy var viewModel = MainViewModel(
        dateProvider: dateProvider,
        settings: settings,
        autoUpdater: autoUpdater,
        isAppActive: isAppActive,
        hasPendingInvites: hasPendingInvites,
        notificationCenter: notificationCenter,
        workspace: workspace,
        launchServices: launchServices
    )

    init() {
        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
        dateProvider.now = .make(year: 2021, month: 1, day: 5)
    }

    @Test func testLocalShortcut_showSearchInput() {

        var isSearchInputVisible: Bool?

        viewModel.isSearchInputVisible
            .bind { isSearchInputVisible = $0 }
            .disposed(by: disposeBag)

        #expect(isSearchInputVisible == false)
        #expect(viewModel.handleLocalShortcut(.command(.char("f"))))
        #expect(isSearchInputVisible == true)
    }

    @Test func testLocalShortcut_hideSearchInput() {

        var isSearchInputVisible: Bool?

        viewModel.isSearchInputVisible
            .bind { isSearchInputVisible = $0 }
            .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())

        #expect(isSearchInputVisible == true)
        #expect(viewModel.handleLocalShortcut(.escape))
        #expect(isSearchInputVisible == false)
    }

    @Test func testLocalShortcut_closeInvites() {

        var showInvites: Bool?

        viewModel.showInvites
            .bind { showInvites = $0 }
            .disposed(by: disposeBag)

        viewModel.showInvitesObserver.onNext(true)

        #expect(showInvites == true)
        #expect(viewModel.handleLocalShortcut(.escape))
        #expect(showInvites == false)
    }

    @Test func testLocalShortcut_acceptSearchDateSuggestion() {

        var selectedDate: Date?
        var inputText: String?
        var isSuggestionVisible: Bool?
        var suggestion: DateSuggestionResult?

        viewModel.selectedDate
            .bind { selectedDate = $0 }
            .disposed(by: disposeBag)

        viewModel.searchInputText
            .bind { inputText = $0 }
            .disposed(by: disposeBag)

        viewModel.isSearchInputSuggestionVisible
            .bind { isSuggestionVisible = $0 }
            .disposed(by: disposeBag)

        viewModel.searchInputSuggestion
            .bind { suggestion = $0 }
            .disposed(by: disposeBag)

        #expect(selectedDate == .make(year: 2021, month: 1, day: 5))
        #expect(inputText == "")
        #expect(isSuggestionVisible == false)
        #expect(suggestion == nil)

        viewModel.showSearchInputObserver.onNext(())
        viewModel.searchInputFocusObserver.onNext(true)
        viewModel.searchInputTextObserver.onNext("test 4 mar 26")

        #expect(selectedDate == .make(year: 2021, month: 1, day: 5))
        #expect(inputText == "test 4 mar 26")
        #expect(isSuggestionVisible == true)
        #expect(suggestion?.date == .make(year: 2026, month: 3, day: 4))
        #expect(suggestion?.result == "test")

        #expect(viewModel.handleLocalShortcut(.enter) == true)

        #expect(selectedDate == .make(year: 2026, month: 3, day: 4))
        #expect(inputText == "test")
        #expect(isSuggestionVisible == false)
        #expect(suggestion == nil)
    }

    @Test func testLocalShortcut_handleTermination() {

        var didTerminate = false
        launchServices.didTerminate = { didTerminate = true }

        #expect(viewModel.handleLocalShortcut(.command(.char("q"))))
        #expect(didTerminate)
    }

    @Test func testLocalShortcut_openSettings() {

        var settingsTab: SettingsTab?

        viewModel.openSettings
            .bind { settingsTab = $0.0 }
            .disposed(by: disposeBag)

        #expect(settingsTab == nil)
        #expect(viewModel.handleLocalShortcut(.command(.char(","))))
        #expect(settingsTab == .general)
    }

    @Test func testLocalShortcut_togglePin() {

        var isPinned: Bool?

        viewModel.pinnedObservable
            .bind { isPinned = $0 }
            .disposed(by: disposeBag)

        #expect(isPinned == false)

        #expect(viewModel.handleLocalShortcut(.command(.char("p"))))
        #expect(isPinned == true)

        #expect(viewModel.handleLocalShortcut(.command(.char("p"))))
        #expect(isPinned == false)
    }

    @Test func testLocalShortcut_toggleWeekNumbers() {

        var showWeekNumbers: Bool?

        settings.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        #expect(showWeekNumbers == false)

        #expect(viewModel.handleLocalShortcut(.option(.char("w"))))
        #expect(showWeekNumbers == true)

        #expect(viewModel.handleLocalShortcut(.option(.char("w"))))
        #expect(showWeekNumbers == false)
    }

    @Test func testLocalShortcut_withSeachInput_doNotToggleWeekNumbers() {

        var showWeekNumbers: Bool?

        settings.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        #expect(showWeekNumbers == false)

        viewModel.showSearchInputObserver.onNext(())

        #expect(viewModel.handleLocalShortcut(.option(.char("w"))) == false)
        #expect(showWeekNumbers == false)
    }

    @Test func testLocalShortcut_toggleDeclinedEvents() {

        var showDeclinedEvents: Bool?

        settings.showDeclinedEvents
            .bind { showDeclinedEvents = $0 }
            .disposed(by: disposeBag)

        #expect(showDeclinedEvents == false)

        #expect(viewModel.handleLocalShortcut(.option(.char("d"))))
        #expect(showDeclinedEvents == true)

        #expect(viewModel.handleLocalShortcut(.option(.char("d"))))
        #expect(showDeclinedEvents == false)
    }

    @Test func testLocalShortcut_withSeachInput_doNotToggleDeclinedEvents() {

        var showDeclinedEvents: Bool?

        settings.showDeclinedEvents
            .bind { showDeclinedEvents = $0 }
            .disposed(by: disposeBag)

        #expect(showDeclinedEvents == false)

        viewModel.showSearchInputObserver.onNext(())

        #expect(viewModel.handleLocalShortcut(.option(.char("d"))) == false)
        #expect(showDeclinedEvents == false)
    }

    @Test func testLocalShortcut_openCalendarAtSelectedDate() {

        let expectedDate = Date.make(year: 2021, month: 1, day: 10)

        viewModel.selectDateObserver.onNext(expectedDate)

        var openedDate: Date?
        workspace.didOpenDate = { date, _ in
            openedDate = date
        }

        #expect(viewModel.handleLocalShortcut(.enter))

        #expect(openedDate == expectedDate)
    }

    static let navigationKeys: [Keyboard.Key] = [
        .arrow(.left),
        .arrow(.right),
        .arrow(.up),
        .arrow(.down),
        .command(.arrow(.left)),
        .command(.arrow(.right)),
        .command(.arrow(.up)),
        .command(.arrow(.down)),
        .backspace
    ]

    @Test(arguments: navigationKeys)
    func testLocalShortcut_routeNavigationKeys(key: Keyboard.Key) {

        var navigation: Keyboard.Key?

        viewModel.navigation
            .bind { navigation = $0 }
            .disposed(by: disposeBag)

        #expect(viewModel.handleLocalShortcut(key))
        #expect(navigation == key)
    }

    @Test(arguments: navigationKeys)
    func testLocalShortcut_withSearchInput_doNotRouteNavigationKeys(key: Keyboard.Key) {

        var navigation: Keyboard.Key?

        viewModel.navigation
            .bind { navigation = $0 }
            .disposed(by: disposeBag)

        viewModel.showSearchInputObserver.onNext(())

        #expect(viewModel.handleLocalShortcut(key) == false)
        #expect(navigation == nil)
    }

    @Test func testLocalShortcut_returnsFalseForUnsupportedKey() {

        #expect(viewModel.handleLocalShortcut(.char("x")) == false)
    }
}
