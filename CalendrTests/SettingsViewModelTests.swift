//
//  SettingsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 21/01/21.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class SettingsViewModelTests {

    let disposeBag = DisposeBag()

    let autoLauncher = MockAutoLauncher()
    let autoUpdater = MockAutoUpdater()
    let dateProvider = MockDateProvider()
    let workspace = MockWorkspaceServiceProvider()
    let localStorage = MockLocalStorageProvider()
    let notificationCenter = NotificationCenter()

    let scheduler = HistoricalScheduler()

    lazy var viewModel = SettingsViewModel(
        autoLauncher: autoLauncher,
        autoUpdater: autoUpdater,
        dateProvider: dateProvider,
        workspace: workspace,
        localStorage: localStorage,
        notificationCenter: notificationCenter,
        scheduler: scheduler
    )

    var localStorageStatusItemIconEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemIconEnabled) as? Bool }
    var localStorageStatusItemDateEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemDateEnabled) as? Bool }
    var localStorageStatusItemBackgroundEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemBackgroundEnabled) as? Bool }
    var localStorageStatusItemDateStyle: NSNumber? { localStorage.object(forKey: Prefs.statusItemDateStyle) as? NSNumber }
    var localStorageStatusItemTextScaling: NSNumber? { localStorage.object(forKey: Prefs.statusItemTextScaling) as? NSNumber }
    var localStorageShowEventStatusItem: Bool? { localStorage.object(forKey: Prefs.showEventStatusItem) as? Bool }
    var localStorageEventStatusItemCheckRange: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemCheckRange) as? NSNumber }
    var localStorageEventStatusItemSound: Bool? { localStorage.object(forKey: Prefs.eventStatusItemSound) as? Bool }
    var localStorageEventStatusItemFlashing: Bool? { localStorage.object(forKey: Prefs.eventStatusItemFlashing) as? Bool }
    var localStorageShowFullScreenEvent: Bool? { localStorage.object(forKey: Prefs.showFullScreenEvent) as? Bool }
    var localStorageFullScreenEventTransparencyLevel: NSNumber? { localStorage.object(forKey: Prefs.fullScreenEventTransparencyLevel) as? NSNumber }
    var localStorageEventStatusItemTextScaling: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemTextScaling) as? NSNumber }
    var localStorageEventStatusItemLength: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemLength) as? NSNumber }
    var localStorageEventStatusItemDetectNotch: Bool? { localStorage.object(forKey: Prefs.eventStatusItemDetectNotch) as? Bool }
    var localStorageEventStatusItemNotchLength: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemNotchLength) as? NSNumber }
    var localStorageCalendarScaling: NSNumber? { localStorage.object(forKey: Prefs.calendarScaling) as? NSNumber }
    var localStorageFirstWeekday: NSNumber? { localStorage.object(forKey: Prefs.firstWeekday) as? NSNumber }
    var localStorageHighlightedWeekdays: [Int]? { localStorage.object(forKey: Prefs.highlightedWeekdays) as? [Int] }
    var localStorageShowWeekNumbers: Bool? { localStorage.object(forKey: Prefs.showWeekNumbers) as? Bool }
    var localStorageShowDeclinedEvents: Bool? { localStorage.object(forKey: Prefs.showDeclinedEvents) as? Bool }
    var localStoragePreserveSelectedDate: Bool? { localStorage.object(forKey: Prefs.preserveSelectedDate) as? Bool }
    var localStorageShowMap: Bool? { localStorage.object(forKey: Prefs.showMap) as? Bool }
    var localStorageShowPastEvents: Bool? { localStorage.object(forKey: Prefs.showPastEvents) as? Bool }
    var localStorageShowOverdueReminders: Bool? { localStorage.object(forKey: Prefs.showOverdueReminders) as? Bool }
    var localStorageShowAllDayEvents: Bool? { localStorage.object(forKey: Prefs.showAllDayEvents) as? Bool }
    var localStorageShowAllDayDetails: Bool? { localStorage.object(forKey: Prefs.showAllDayDetails) as? Bool }
    var localStorageShowRecurrenceIndicator: Bool? { localStorage.object(forKey: Prefs.showRecurrenceIndicator) as? Bool }
    var localStorageShowEventListSummary: Bool? { localStorage.object(forKey: Prefs.showEventListSummary) as? Bool }
    var localStorageTransparency: NSNumber? { localStorage.object(forKey: Prefs.transparencyLevel) as? NSNumber }
    var localStorageAppearanceMode: NSNumber? { localStorage.object(forKey: Prefs.appearanceMode) as? NSNumber }
    var localStorageEventDotsStyle: String? { localStorage.object(forKey: Prefs.eventDotsStyle) as! String? }
    var localStorageFutureEventsDays: NSNumber? { localStorage.object(forKey: Prefs.futureEventsDays) as? NSNumber }
    var localStorageShowMonthOutline: Bool? { localStorage.object(forKey: Prefs.showMonthOutline) as? Bool }
    var localStorageAutoCheckForUpdates: Bool? { localStorage.object(forKey: Prefs.autoCheckForUpdates) as? Bool }

    init() {

        localStorage.reset()

        #expect(localStorageStatusItemIconEnabled == nil)
        #expect(localStorageStatusItemDateEnabled == nil)
        #expect(localStorageStatusItemBackgroundEnabled == nil)
        #expect(localStorageStatusItemDateStyle == nil)
        #expect(localStorageStatusItemTextScaling == nil)
        #expect(localStorageShowEventStatusItem == nil)
        #expect(localStorageEventStatusItemCheckRange == nil)
        #expect(localStorageEventStatusItemSound == nil)
        #expect(localStorageEventStatusItemFlashing == nil)
        #expect(localStorageShowFullScreenEvent == nil)
        #expect(localStorageFullScreenEventTransparencyLevel == nil)
        #expect(localStorageEventStatusItemTextScaling == nil)
        #expect(localStorageEventStatusItemLength == nil)
        #expect(localStorageEventStatusItemDetectNotch == nil)
        #expect(localStorageEventStatusItemNotchLength == nil)
        #expect(localStorageCalendarScaling == nil)
        #expect(localStorageFirstWeekday == nil)
        #expect(localStorageHighlightedWeekdays == nil)
        #expect(localStorageShowWeekNumbers == nil)
        #expect(localStorageShowDeclinedEvents == nil)
        #expect(localStoragePreserveSelectedDate == nil)
        #expect(localStorageShowMap == nil)
        #expect(localStorageShowPastEvents == nil)
        #expect(localStorageShowOverdueReminders == nil)
        #expect(localStorageShowAllDayEvents == nil)
        #expect(localStorageShowAllDayDetails == nil)
        #expect(localStorageShowRecurrenceIndicator == nil)
        #expect(localStorageShowEventListSummary == nil)
        #expect(localStorageTransparency == nil)
        #expect(localStorageEventDotsStyle == nil)
        #expect(localStorageFutureEventsDays == nil)
        #expect(localStorageShowMonthOutline == nil)
        #expect(localStorageAutoCheckForUpdates == nil)

        registerDefaultPrefs(in: localStorage, calendar: .gregorian.with(firstWeekday: 3))
    }

    @Test func testDefaultSettings() {

        #expect(viewModel.showStatusItemIcon.lastValue() == true)
        #expect(viewModel.showStatusItemDate.lastValue() == true)
        #expect(viewModel.showStatusItemBackground.lastValue() == false)
        #expect(viewModel.statusItemDateStyle.lastValue() == .short)
        #expect(viewModel.statusItemTextScaling.lastValue() == 1.2)
        #expect(viewModel.showEventStatusItem.lastValue() == false)
        #expect(viewModel.eventStatusItemTextScaling.lastValue() == 1.2)
        #expect(viewModel.eventStatusItemCheckRange.lastValue() == 6)
        #expect(viewModel.eventStatusItemSound.lastValue() == false)
        #expect(viewModel.eventStatusItemFlashing.lastValue() == false)
        #expect(viewModel.showFullScreenEvent.lastValue() == false)
        #expect(viewModel.eventStatusItemLength.lastValue() == 18)
        #expect(viewModel.eventStatusItemDetectNotch.lastValue() == false)
        #expect(viewModel.eventStatusItemNotchLength.lastValue() == 6)
        #expect(viewModel.calendarScaling.lastValue() == 1)
        #expect(viewModel.firstWeekday.lastValue() == 3)
        #expect(viewModel.highlightedWeekdays.lastValue() == [0, 6])
        #expect(viewModel.showWeekNumbers.lastValue() == false)
        #expect(viewModel.showDeclinedEvents.lastValue() == false)
        #expect(viewModel.preserveSelectedDate.lastValue() == false)
        #expect(viewModel.showMap.lastValue() == true)
        #expect(viewModel.showPastEvents.lastValue() == true)
        #expect(viewModel.showOverdueReminders.lastValue() == true)
        #expect(viewModel.showAllDayEvents.lastValue() == true)
        #expect(viewModel.showAllDayDetails.lastValue() == true)
        #expect(viewModel.showRecurrenceIndicator.lastValue() == true)
        #expect(viewModel.showEventListSummary.lastValue() == true)
        #expect(viewModel.popoverTransparency.lastValue() == 2)
        #expect(viewModel.popoverMaterial.lastValue() == .headerView)
        #expect(viewModel.appearanceMode.lastValue() == .automatic)
        #expect(viewModel.eventDotsStyle.lastValue() == .multiple)
        #expect(viewModel.futureEventsDays.lastValue() == 0)
        #expect(viewModel.showMonthOutline.lastValue() == true)
        #expect(viewModel.autoCheckForUpdates.lastValue() == true)

        #expect(localStorageStatusItemIconEnabled == true)
        #expect(localStorageStatusItemDateEnabled == true)
        #expect(localStorageStatusItemBackgroundEnabled == false)
        #expect(localStorageStatusItemTextScaling == 1.2)
        #expect(localStorageStatusItemDateStyle == 1)
        #expect(localStorageShowEventStatusItem == false)
        #expect(localStorageEventStatusItemTextScaling == 1.2)
        #expect(localStorageEventStatusItemCheckRange == 6)
        #expect(localStorageEventStatusItemSound == false)
        #expect(localStorageEventStatusItemFlashing == false)
        #expect(localStorageShowFullScreenEvent == false)
        #expect(localStorageEventStatusItemLength == 18)
        #expect(localStorageEventStatusItemDetectNotch == false)
        #expect(localStorageEventStatusItemNotchLength == 6)
        #expect(localStorageCalendarScaling == 1)
        #expect(localStorageFirstWeekday == 3)
        #expect(localStorageHighlightedWeekdays == [0, 6])
        #expect(localStorageShowWeekNumbers == false)
        #expect(localStorageShowDeclinedEvents == false)
        #expect(localStoragePreserveSelectedDate == false)
        #expect(localStorageShowMap == true)
        #expect(localStorageShowPastEvents == true)
        #expect(localStorageShowOverdueReminders == true)
        #expect(localStorageShowRecurrenceIndicator == true)
        #expect(localStorageShowEventListSummary == true)
        #expect(localStorageTransparency == 2)
        #expect(localStorageFullScreenEventTransparencyLevel == 2)
        #expect(localStorageAppearanceMode == 0)
        #expect(localStorageEventDotsStyle == EventDotsStyle.multiple.rawValue)
        #expect(localStorageFutureEventsDays == 0)
        #expect(localStorageShowMonthOutline == true)
        #expect(localStorageAutoCheckForUpdates == true)
    }

    @Test func testSetStatusItemsInitialPositions() {

        let names = [
            StatusItemName.main,
            StatusItemName.event,
            StatusItemName.reminder
        ]

        for name in names {
            let key = statusItemPreferredPositionKey(name, .visible)
            let savedKey = statusItemPreferredPositionKey(name, .saved)
            #expect(localStorage.integer(forKey: key) == 0)
            #expect(localStorage.integer(forKey: savedKey) == 0)
        }

        setInitialStatusItemPositions(in: localStorage)

        for name in names {
            let key = statusItemPreferredPositionKey(name, .visible)
            let savedKey = statusItemPreferredPositionKey(name, .saved)
            #expect(localStorage.integer(forKey: key) == 100)
            #expect(localStorage.integer(forKey: savedKey) == 100)
        }
    }

    @Test func testSetStatusItemsInitialPositions_keepsExistingPositions() {

        let names = [
            StatusItemName.main,
            StatusItemName.event,
            StatusItemName.reminder
        ]

        for name in names {
            let key = statusItemPreferredPositionKey(name, .visible)
            let savedKey = statusItemPreferredPositionKey(name, .saved)
            #expect(localStorage.integer(forKey: savedKey) == 0)
            localStorage.set(123, forKey: key)
        }

        setInitialStatusItemPositions(in: localStorage)

        for name in names {
            let key = statusItemPreferredPositionKey(name, .visible)
            let savedKey = statusItemPreferredPositionKey(name, .saved)
            #expect(localStorage.integer(forKey: key) == 123)
            #expect(localStorage.integer(forKey: savedKey) == 123)
        }
    }

    @Test func testDateFormatOptions() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let options = viewModel.dateFormatOptions.lastValue()

        #expect(options == [
            .init(style: .short, title: "1/1/21"),
            .init(style: .medium, title: "Jan 1, 2021"),
            .init(style: .long, title: "January 1, 2021"),
            .init(style: .full, title: "Friday, January 1, 2021"),
            .init(style: .none, title: "Custom")
        ])
    }

    @Test func testDateFormatOptions_withLocaleChange() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        var options: [SettingsViewModel.DateFormatOption]?

        viewModel.dateFormatOptions
            .bind { options = $0 }
            .disposed(by: disposeBag)

        #expect(options?.first == .init(style: .short, title: "1/1/21"))

        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")

        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        #expect(options?.first == .init(style: .short, title: "01/01/2021"))
    }

    @Test func testEventDotsStyle() {
        localStorage.eventDotsStyle = EventDotsStyle.single_neutral.rawValue
        #expect(localStorageEventDotsStyle == EventDotsStyle.single_neutral.rawValue)

        var eventDotsStyle: EventDotsStyle?

        viewModel.eventDotsStyle
            .bind { eventDotsStyle = $0 }
            .disposed(by: disposeBag)

        #expect(eventDotsStyle == .single_neutral)

        viewModel.eventDotsStyleObserver.onNext(.single_highlighted)

        #expect(eventDotsStyle == .single_highlighted)
        #expect(localStorageEventDotsStyle == EventDotsStyle.single_highlighted.rawValue)
    }

    @Test func testCalendarAppViewModeOptions_pt() {

        dateProvider.m_calendar.locale = Locale(identifier: "pt")

        #expect(viewModel.calendarAppViewModeOptions.map(\.title) == ["mês", "semana", "dia"])
    }

    @Test func testCalendarAppViewModeOptions_de() {

        dateProvider.m_calendar.locale = Locale(identifier: "de")

        #expect(viewModel.calendarAppViewModeOptions.map(\.title) == ["Monat", "Woche", "Tag"])
    }

    @Test func testDateStyleSelected() {

        localStorage.statusItemDateStyle = 1
        #expect(localStorageStatusItemDateStyle == 1)

        var statusItemDateStyle: StatusItemDateStyle?

        viewModel.statusItemDateStyle
            .bind { statusItemDateStyle = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyleObserver.onNext(.medium)

        #expect(statusItemDateStyle == .medium)
        #expect(localStorageStatusItemDateStyle == 2)
    }

    @Test func testCustomDateStyleSelected() throws {

        localStorage.statusItemDateStyle = 0
        #expect(localStorageStatusItemDateStyle == 0)

        var isDateFormatInputVisible: Bool?

        viewModel.isDateFormatInputVisible
            .bind { isDateFormatInputVisible = $0 }
            .disposed(by: disposeBag)

        #expect(isDateFormatInputVisible == true)

        viewModel.statusItemDateStyleObserver.onNext(.short)
        #expect(isDateFormatInputVisible == false)

        // this should fail, but it doesn't, so we test it ¯\_(ツ)_/¯
        viewModel.statusItemDateStyleObserver.onNext(try #require(.init(rawValue: 5)))
        #expect(isDateFormatInputVisible == true)

        viewModel.statusItemDateStyleObserver.onNext(.full)
        #expect(isDateFormatInputVisible == false)

        viewModel.statusItemDateStyleObserver.onNext(.none)
        #expect(isDateFormatInputVisible == true)
    }

    @Test func testToggleAutoLaunch() {

        var autoLaunch: Bool?

        viewModel.autoLaunch
            .bind { autoLaunch = $0 }
            .disposed(by: disposeBag)

        #expect(autoLaunch == false)
        #expect(autoLauncher.isLoginItemEnabled == false)

        viewModel.toggleAutoLaunch.onNext(true)

        #expect(autoLaunch == true)
        #expect(autoLauncher.isLoginItemEnabled == true)
    }

    @Test func testToggleLaunchAgent() {

        var launchAgent: Bool?

        viewModel.launchAgent
            .bind { launchAgent = $0 }
            .disposed(by: disposeBag)

        #expect(launchAgent == false)
        #expect(autoLauncher.isLaunchAgentEnabled == false)

        viewModel.toggleLaunchAgent.onNext(true)

        #expect(launchAgent == true)
        #expect(autoLauncher.isLaunchAgentEnabled == true)
    }

    @Test func testToggleAutoCheckForUpdates() {

        localStorage.autoCheckForUpdates = false

        var autoCheckForUpdates: Bool?

        viewModel.autoCheckForUpdates
            .bind { autoCheckForUpdates = $0 }
            .disposed(by: disposeBag)

        #expect(autoCheckForUpdates == false)
        #expect(localStorageAutoCheckForUpdates == false)

        viewModel.toggleAutoCheckForUpdates.onNext(true)

        #expect(autoCheckForUpdates == true)
        #expect(localStorageAutoCheckForUpdates == true)

        viewModel.toggleAutoCheckForUpdates.onNext(false)

        #expect(autoCheckForUpdates == false)
        #expect(localStorageAutoCheckForUpdates == false)
    }

    @Test func testAutoCheckForUpdatesStart() async {

        let startExpectation = expectation(description: "Start")

        let stopExpectation = expectation(description: "Stop")
        stopExpectation.isInverted = true

        autoUpdater.didStart = startExpectation.fulfill
        autoUpdater.didStop = stopExpectation.fulfill

        viewModel.toggleAutoCheckForUpdates.onNext(true)
        scheduler.advance(.seconds(5))

        await fulfillment(of: [startExpectation, stopExpectation])
    }

    @Test func testAutoCheckForUpdatesStop() async {

        let startExpectation = expectation(description: "Start")
        startExpectation.isInverted = true

        let stopExpectation = expectation(description: "Stop")

        autoUpdater.didStart = startExpectation.fulfill
        autoUpdater.didStop = stopExpectation.fulfill

        viewModel.toggleAutoCheckForUpdates.onNext(false)
        scheduler.advance(.seconds(5))

        await fulfillment(of: [startExpectation, stopExpectation])
    }

    @Test func testToggleShowEventStatusItem() {

        localStorage.showEventStatusItem = true

        var showEventStatusItem: Bool?

        viewModel.showEventStatusItem
            .bind { showEventStatusItem = $0 }
            .disposed(by: disposeBag)

        #expect(showEventStatusItem == true)
        #expect(localStorageShowEventStatusItem == true)

        viewModel.toggleEventStatusItem.onNext(false)

        #expect(showEventStatusItem == false)
        #expect(localStorageShowEventStatusItem == false)

        viewModel.toggleEventStatusItem.onNext(true)

        #expect(showEventStatusItem == true)
        #expect(localStorageShowEventStatusItem == true)
    }

    @Test func testToggleEventStatusItemSound() {

        localStorage.eventStatusItemSound = true

        var eventStatusItemSound: Bool?

        viewModel.eventStatusItemSound
            .bind { eventStatusItemSound = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemSound == true)
        #expect(localStorageEventStatusItemSound == true)

        viewModel.toggleEventStatusItemSound.onNext(false)

        #expect(eventStatusItemSound == false)
        #expect(localStorageEventStatusItemSound == false)

        viewModel.toggleEventStatusItemSound.onNext(true)

        #expect(eventStatusItemSound == true)
        #expect(localStorageEventStatusItemSound == true)
    }

    @Test func testToggleEventStatusItemFlashing() {

        localStorage.eventStatusItemFlashing = true

        var eventStatusItemFlashing: Bool?

        viewModel.eventStatusItemFlashing
            .bind { eventStatusItemFlashing = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemFlashing == true)
        #expect(localStorageEventStatusItemFlashing == true)

        viewModel.toggleEventStatusItemFlashing.onNext(false)

        #expect(eventStatusItemFlashing == false)
        #expect(localStorageEventStatusItemFlashing == false)

        viewModel.toggleEventStatusItemFlashing.onNext(true)

        #expect(eventStatusItemFlashing == true)
        #expect(localStorageEventStatusItemFlashing == true)
    }

    @Test func testToggleShowFullScreenEvent() {

        localStorage.showFullScreenEvent = true

        var showFullScreenEvent: Bool?

        viewModel.showFullScreenEvent
            .bind { showFullScreenEvent = $0 }
            .disposed(by: disposeBag)

        #expect(showFullScreenEvent == true)
        #expect(localStorageShowFullScreenEvent == true)

        viewModel.toggleFullScreenEvent.onNext(false)

        #expect(showFullScreenEvent == false)
        #expect(localStorageShowFullScreenEvent == false)

        viewModel.toggleFullScreenEvent.onNext(true)

        #expect(showFullScreenEvent == true)
        #expect(localStorageShowFullScreenEvent == true)
    }

    @Test func testChangeEventStatusItemLength() {

        localStorage.eventStatusItemLength = 20

        var eventStatusItemLength: Int?

        viewModel.eventStatusItemLength
            .bind { eventStatusItemLength = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemLength == 20)
        #expect(localStorageEventStatusItemLength == 20)

        viewModel.eventStatusItemLengthObserver.onNext(30)

        #expect(eventStatusItemLength == 30)
        #expect(localStorageEventStatusItemLength == 30)
    }

    @Test func testChangeEventStatusItemNotchLength() {

        localStorage.eventStatusItemNotchLength = 6

        var eventStatusItemNotchLength: Int?

        viewModel.eventStatusItemNotchLength
            .bind { eventStatusItemNotchLength = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemNotchLength == 6)
        #expect(localStorageEventStatusItemNotchLength == 6)

        viewModel.eventStatusItemNotchLengthObserver.onNext(2)

        #expect(eventStatusItemNotchLength == 2)
        #expect(localStorageEventStatusItemNotchLength == 2)
    }

    @Test func testChangeEventStatusItemCheckRange() {

        localStorage.eventStatusItemCheckRange = 12

        var eventStatusItemCheckRange: Int?
        var eventStatusItemCheckRangeLabel: String?

        viewModel.eventStatusItemCheckRange
            .bind { eventStatusItemCheckRange = $0 }
            .disposed(by: disposeBag)

        viewModel.eventStatusItemCheckRangeLabel
            .bind { eventStatusItemCheckRangeLabel = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemCheckRange == 12)
        #expect(eventStatusItemCheckRangeLabel == "in 12 hours")
        #expect(localStorageEventStatusItemCheckRange == 12)

        viewModel.eventStatusItemCheckRangeObserver.onNext(18)

        #expect(eventStatusItemCheckRange == 18)
        #expect(eventStatusItemCheckRangeLabel == "in 18 hours")
        #expect(localStorageEventStatusItemCheckRange == 18)
    }

    @Test func testEventStatusItemCheckRangeZero_shouldDisplay30min() {

        viewModel.eventStatusItemCheckRangeObserver.onNext(0)

        #expect(viewModel.eventStatusItemCheckRange.lastValue() == 0)
        #expect(viewModel.eventStatusItemCheckRangeLabel.lastValue() == "in 30 minutes")
        #expect(localStorageEventStatusItemCheckRange == 0)
    }

    @Test func testToggleEventStatusItemDetectNotch() {

        localStorage.eventStatusItemDetectNotch = true

        var eventStatusItemDetectNotch: Bool?

        viewModel.eventStatusItemDetectNotch
            .bind { eventStatusItemDetectNotch = $0 }
            .disposed(by: disposeBag)

        #expect(eventStatusItemDetectNotch == true)
        #expect(localStorageEventStatusItemDetectNotch == true)

        viewModel.toggleEventStatusItemDetectNotch.onNext(false)

        #expect(eventStatusItemDetectNotch == false)
        #expect(localStorageEventStatusItemDetectNotch == false)

        viewModel.toggleEventStatusItemDetectNotch.onNext(true)

        #expect(eventStatusItemDetectNotch == true)
        #expect(localStorageEventStatusItemDetectNotch == true)
    }

    @Test func testChangeCalendarScaling() {

        localStorage.calendarScaling = 1.2

        var calendarScaling: Double?

        viewModel.calendarScaling
            .bind { calendarScaling = $0 }
            .disposed(by: disposeBag)

        #expect(calendarScaling == 1.2)
        #expect(localStorageCalendarScaling == 1.2)

        viewModel.calendarScalingObserver.onNext(1.1)

        #expect(calendarScaling == 1.1)
        #expect(localStorageCalendarScaling == 1.1)
    }

    @Test func testChangeFirstWeekday() {

        localStorage.firstWeekday = 1

        var firstWeekday: Int?

        viewModel.firstWeekday
            .bind { firstWeekday = $0 }
            .disposed(by: disposeBag)

        #expect(firstWeekday == 1)
        #expect(localStorageFirstWeekday == 1)

        viewModel.firstWeekdayNextObserver.onNext(())

        #expect(firstWeekday == 2)
        #expect(localStorageFirstWeekday == 2)

        localStorage.firstWeekday = 7

        viewModel.firstWeekdayNextObserver.onNext(())

        #expect(firstWeekday == 1)
        #expect(localStorageFirstWeekday == 1)

        viewModel.firstWeekdayPrevObserver.onNext(())

        #expect(firstWeekday == 7)
        #expect(localStorageFirstWeekday == 7)
    }

    @Test func testChangeHighlightedWeekdays() {

        localStorage.highlightedWeekdays = []

        var highlightedWeekdays: [Int]?

        viewModel.highlightedWeekdays
            .bind { highlightedWeekdays = $0 }
            .disposed(by: disposeBag)

        #expect(highlightedWeekdays == [])
        #expect(localStorageHighlightedWeekdays == [])

        viewModel.toggleHighlightedWeekday.onNext(1)

        #expect(highlightedWeekdays == [1])
        #expect(localStorageHighlightedWeekdays == [1])

        viewModel.toggleHighlightedWeekday.onNext(2)

        #expect(highlightedWeekdays == [1, 2])
        #expect(localStorageHighlightedWeekdays == [1, 2])

        viewModel.toggleHighlightedWeekday.onNext(2)

        #expect(highlightedWeekdays == [1])
        #expect(localStorageHighlightedWeekdays == [1])
    }

    @Test func testToggleShowWeekNumbers() {

        localStorage.showWeekNumbers = true

        var showWeekNumbers: Bool?

        viewModel.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        #expect(showWeekNumbers == true)
        #expect(localStorageShowWeekNumbers == true)

        viewModel.toggleWeekNumbers.onNext(false)

        #expect(showWeekNumbers == false)
        #expect(localStorageShowWeekNumbers == false)

        viewModel.toggleWeekNumbers.onNext(true)

        #expect(showWeekNumbers == true)
        #expect(localStorageShowWeekNumbers == true)
    }

    @Test func testToggleShowDeclinedEvents() {

        localStorage.showDeclinedEvents = true

        var showDeclinedEvents: Bool?

        viewModel.showDeclinedEvents
            .bind { showDeclinedEvents = $0 }
            .disposed(by: disposeBag)

        #expect(showDeclinedEvents == true)
        #expect(localStorageShowDeclinedEvents == true)

        viewModel.toggleDeclinedEvents.onNext(false)

        #expect(showDeclinedEvents == false)
        #expect(localStorageShowDeclinedEvents == false)

        viewModel.toggleDeclinedEvents.onNext(true)

        #expect(showDeclinedEvents == true)
        #expect(localStorageShowDeclinedEvents == true)
    }

    @Test func testTogglePreserveSelectedDate() {

        localStorage.preserveSelectedDate = true

        var preserveSelectedDate: Bool?

        viewModel.preserveSelectedDate
            .bind { preserveSelectedDate = $0 }
            .disposed(by: disposeBag)

        #expect(preserveSelectedDate == true)
        #expect(localStoragePreserveSelectedDate == true)

        viewModel.togglePreserveSelectedDate.onNext(false)

        #expect(preserveSelectedDate == false)
        #expect(localStoragePreserveSelectedDate == false)

        viewModel.togglePreserveSelectedDate.onNext(true)

        #expect(preserveSelectedDate == true)
        #expect(localStoragePreserveSelectedDate == true)
    }

    @Test func testToggleShowMap() {

        localStorage.showMap = false

        var showMap: Bool?

        viewModel.showMap
            .bind { showMap = $0 }
            .disposed(by: disposeBag)

        #expect(showMap == false)
        #expect(localStorageShowMap == false)

        viewModel.toggleMap.onNext(true)

        #expect(showMap == true)
        #expect(localStorageShowMap == true)

        viewModel.toggleMap.onNext(false)

        #expect(showMap == false)
        #expect(localStorageShowMap == false)
    }

    @Test func testToggleShowPastEvents() {

        localStorage.showPastEvents = false

        var showPastEvents: Bool?

        viewModel.showPastEvents
            .bind { showPastEvents = $0 }
            .disposed(by: disposeBag)

        #expect(showPastEvents == false)
        #expect(localStorageShowPastEvents == false)

        viewModel.togglePastEvents.onNext(true)

        #expect(showPastEvents == true)
        #expect(localStorageShowPastEvents == true)

        viewModel.togglePastEvents.onNext(false)

        #expect(showPastEvents == false)
        #expect(localStorageShowPastEvents == false)
    }

    @Test func testToggleShowOverdueReminders() {

        localStorage.showOverdueReminders = false

        var showOverdueReminders: Bool?

        viewModel.showOverdueReminders
            .bind { showOverdueReminders = $0 }
            .disposed(by: disposeBag)

        #expect(showOverdueReminders == false)
        #expect(localStorageShowOverdueReminders == false)

        viewModel.toggleOverdueReminders.onNext(true)

        #expect(showOverdueReminders == true)
        #expect(localStorageShowOverdueReminders == true)

        viewModel.toggleOverdueReminders.onNext(false)

        #expect(showOverdueReminders == false)
        #expect(localStorageShowOverdueReminders == false)
    }

    @Test func testToggleShowAllDayEvents() {

        localStorage.showAllDayEvents = false

        var showAllDayEvents: Bool?

        viewModel.showAllDayEvents
            .bind { showAllDayEvents = $0 }
            .disposed(by: disposeBag)

        #expect(showAllDayEvents == false)
        #expect(localStorageShowAllDayEvents == false)

        viewModel.toggleAllDayEvents.onNext(true)

        #expect(showAllDayEvents == true)
        #expect(localStorageShowAllDayEvents == true)

        viewModel.toggleAllDayEvents.onNext(false)

        #expect(showAllDayEvents == false)
        #expect(localStorageShowAllDayEvents == false)
    }

    @Test func testToggleShowAllDayDetails() {

        localStorage.showAllDayDetails = false

        var showAllDayDetails: Bool?

        viewModel.showAllDayDetails
            .bind { showAllDayDetails = $0 }
            .disposed(by: disposeBag)

        #expect(showAllDayDetails == false)
        #expect(localStorageShowAllDayDetails == false)

        viewModel.toggleAllDayDetails.onNext(true)

        #expect(showAllDayDetails == true)
        #expect(localStorageShowAllDayDetails == true)

        viewModel.toggleAllDayDetails.onNext(false)

        #expect(showAllDayDetails == false)
        #expect(localStorageShowAllDayDetails == false)
    }

    @Test func testToggleShowRecurrenceIndicator() {

        localStorage.showRecurrenceIndicator = false

        var showRecurrenceIndicator: Bool?

        viewModel.showRecurrenceIndicator
            .bind { showRecurrenceIndicator = $0 }
            .disposed(by: disposeBag)

        #expect(showRecurrenceIndicator == false)
        #expect(localStorageShowRecurrenceIndicator == false)

        viewModel.toggleRecurrenceIndicator.onNext(true)

        #expect(showRecurrenceIndicator == true)
        #expect(localStorageShowRecurrenceIndicator == true)

        viewModel.toggleRecurrenceIndicator.onNext(false)

        #expect(showRecurrenceIndicator == false)
        #expect(localStorageShowRecurrenceIndicator == false)
    }

    @Test func testToggleShowEventListSummary() {

        localStorage.showEventListSummary = false

        var showEventListSummary: Bool?

        viewModel.showEventListSummary
            .bind { showEventListSummary = $0 }
            .disposed(by: disposeBag)

        #expect(showEventListSummary == false)
        #expect(localStorageShowEventListSummary == false)

        viewModel.toggleEventListSummary.onNext(true)

        #expect(showEventListSummary == true)
        #expect(localStorageShowEventListSummary == true)

        viewModel.toggleEventListSummary.onNext(false)

        #expect(showEventListSummary == false)
        #expect(localStorageShowEventListSummary == false)
    }

    @Test func testChangeTransparency() {

        localStorage.transparencyLevel = 5

        var popoverTransparency: Int?
        var popoverMaterial: PopoverMaterial?

        viewModel.popoverTransparency
            .bind { popoverTransparency = $0 }
            .disposed(by: disposeBag)

        viewModel.popoverMaterial
            .bind { popoverMaterial = $0 }
            .disposed(by: disposeBag)

        let expected: [PopoverMaterial] = [
            .contentBackground,
            .sheet,
            .headerView,
            .menu,
            .popover,
            .hudWindow
        ]

        #expect(popoverTransparency == 5)
        #expect(localStorageTransparency == 5)
        #expect(popoverMaterial == expected[5])

        for level in 0..<expected.count {

            viewModel.transparencyObserver.onNext(level)

            #expect(popoverTransparency == level)
            #expect(localStorageTransparency?.intValue == level)
            #expect(popoverMaterial == expected[level])
        }
    }

    @Test func testToggleStatusItemIcon() {

        localStorage.statusItemIconEnabled = false

        var statusItemIconEnabled: Bool?

        viewModel.showStatusItemIcon
            .bind { statusItemIconEnabled = $0 }
            .disposed(by: disposeBag)

        #expect(statusItemIconEnabled == false)
        #expect(localStorageStatusItemIconEnabled == false)

        viewModel.toggleStatusItemIcon.onNext(true)

        #expect(statusItemIconEnabled == true)
        #expect(localStorageStatusItemIconEnabled == true)

        viewModel.toggleStatusItemIcon.onNext(false)

        #expect(statusItemIconEnabled == false)
        #expect(localStorageStatusItemIconEnabled == false)
    }

    @Test func testToggleStatusItemDate() {

        localStorage.statusItemDateEnabled = false

        var statusItemDateEnabled: Bool?

        viewModel.showStatusItemDate
            .bind { statusItemDateEnabled = $0 }
            .disposed(by: disposeBag)

        #expect(statusItemDateEnabled == false)
        #expect(localStorageStatusItemDateEnabled == false)

        viewModel.toggleStatusItemDate.onNext(true)

        #expect(statusItemDateEnabled == true)
        #expect(localStorageStatusItemDateEnabled == true)

        viewModel.toggleStatusItemDate.onNext(false)

        #expect(statusItemDateEnabled == false)
        #expect(localStorageStatusItemDateEnabled == false)
    }

    @Test func testToggleShowStatusItemBackground() {

        localStorage.statusItemBackgroundEnabled = true

        var showBackground: Bool?

        viewModel.showStatusItemBackground
            .bind { showBackground = $0 }
            .disposed(by: disposeBag)

        #expect(showBackground == true)
        #expect(localStorageStatusItemBackgroundEnabled == true)

        viewModel.toggleStatusItemBackground.onNext(false)

        #expect(showBackground == false)
        #expect(localStorageStatusItemBackgroundEnabled == false)

        viewModel.toggleStatusItemBackground.onNext(true)

        #expect(showBackground == true)
        #expect(localStorageStatusItemBackgroundEnabled == true)
    }

    @Test func testChangeAppearance() {

        for mode in AppearanceMode.allCases {
            viewModel.appearanceModeObserver.onNext(mode)

            #expect(viewModel.appearanceMode.lastValue() == mode)
            #expect(localStorageAppearanceMode?.intValue == mode.rawValue)
        }
    }

    @Test func testChangeFutureEventsDays() {

        localStorage.futureEventsDays = 1

        var futureEventsDays: Int?
        var futureEventsStepperLabel: String?

        viewModel.futureEventsDays
            .bind { futureEventsDays = $0 }
            .disposed(by: disposeBag)

        viewModel.futureEventsStepperLabel
            .bind { futureEventsStepperLabel = $0 }
            .disposed(by: disposeBag)

        #expect(futureEventsDays == 1)
        #expect(futureEventsStepperLabel == "in 1 day")
        #expect(localStorageFutureEventsDays == 1)

        viewModel.futureEventsDaysObserver.onNext(5)

        #expect(futureEventsDays == 5)
        #expect(futureEventsStepperLabel == "in 5 days")
        #expect(localStorageFutureEventsDays == 5)
    }

    @Test func testToggleShowMonthOutline() {

        localStorage.showMonthOutline = true

        var showMonthOutline: Bool?

        viewModel.showMonthOutline
            .bind { showMonthOutline = $0 }
            .disposed(by: disposeBag)

        #expect(showMonthOutline == true)
        #expect(localStorageShowMonthOutline == true)

        viewModel.toggleMonthOutline.onNext(false)

        #expect(showMonthOutline == false)
        #expect(localStorageShowMonthOutline == false)

        viewModel.toggleMonthOutline.onNext(true)

        #expect(showMonthOutline == true)
        #expect(localStorageShowMonthOutline == true)
    }
}
