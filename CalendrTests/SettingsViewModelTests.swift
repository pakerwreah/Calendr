//
//  SettingsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 21/01/21.
//

import XCTest
import RxSwift
@testable import Calendr

class SettingsViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    let autoLauncher = AutoLauncher()
    let dateProvider = MockDateProvider()
    let workspace = MockWorkspaceServiceProvider()
    let localStorage = MockLocalStorageProvider()
    let notificationCenter = NotificationCenter()

    lazy var viewModel = SettingsViewModel(
        autoLauncher: autoLauncher,
        dateProvider: dateProvider,
        workspace: workspace,
        localStorage: localStorage,
        notificationCenter: notificationCenter
    )

    var localStorageStatusItemIconEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemIconEnabled) as? Bool }
    var localStorageStatusItemDateEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemDateEnabled) as? Bool }
    var localStorageStatusItemBackgroundEnabled: Bool? { localStorage.object(forKey: Prefs.statusItemBackgroundEnabled) as? Bool }
    var localStorageStatusItemDateStyle: NSNumber? { localStorage.object(forKey: Prefs.statusItemDateStyle) as? NSNumber }
    var localStorageStatusItemTextScaling: NSNumber? { localStorage.object(forKey: Prefs.statusItemTextScaling) as? NSNumber }
    var localStorageShowEventStatusItem: Bool? { localStorage.object(forKey: Prefs.showEventStatusItem) as? Bool }
    var localStorageEventStatusItemCheckRange: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemCheckRange) as? NSNumber }
    var localStorageEventStatusItemTextScaling: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemTextScaling) as? NSNumber }
    var localStorageEventStatusItemLength: NSNumber? { localStorage.object(forKey: Prefs.eventStatusItemLength) as? NSNumber }
    var localStorageEventStatusItemDetectNotch: Bool? { localStorage.object(forKey: Prefs.eventStatusItemDetectNotch) as? Bool }
    var localStorageCalendarScaling: NSNumber? { localStorage.object(forKey: Prefs.calendarScaling) as? NSNumber }
    var localStorageFirstWeekday: NSNumber? { localStorage.object(forKey: Prefs.firstWeekday) as? NSNumber }
    var localStorageHighlightedWeekdays: [Int]? { localStorage.object(forKey: Prefs.highlightedWeekdays) as? [Int] }
    var localStorageShowWeekNumbers: Bool? { localStorage.object(forKey: Prefs.showWeekNumbers) as? Bool }
    var localStorageShowDeclinedEvents: Bool? { localStorage.object(forKey: Prefs.showDeclinedEvents) as? Bool }
    var localStoragePreserveSelectedDate: Bool? { localStorage.object(forKey: Prefs.preserveSelectedDate) as? Bool }
    var localStorageShowMap: Bool? { localStorage.object(forKey: Prefs.showMap) as? Bool }
    var localStorageShowPastEvents: Bool? { localStorage.object(forKey: Prefs.showPastEvents) as? Bool }
    var localStorageShowOverdueReminders: Bool? { localStorage.object(forKey: Prefs.showOverdueReminders) as? Bool }
    var localStorageShowAllDayDetails: Bool? { localStorage.object(forKey: Prefs.showAllDayDetails) as? Bool }
    var localStorageShowRecurrenceIndicator: Bool? { localStorage.object(forKey: Prefs.showRecurrenceIndicator) as? Bool }
    var localStorageShowEventListSummary: Bool? { localStorage.object(forKey: Prefs.showEventListSummary) as? Bool }
    var localStorageTransparency: NSNumber? { localStorage.object(forKey: Prefs.transparencyLevel) as? NSNumber }
    var localStorageAppearanceMode: NSNumber? { localStorage.object(forKey: Prefs.appearanceMode) as? NSNumber }
    var localStorageEventDotsStyle: String? { localStorage.object(forKey: Prefs.eventDotsStyle) as! String? }
    var localStorageFutureEventsDays: NSNumber? { localStorage.object(forKey: Prefs.futureEventsDays) as? NSNumber }
    var localStorageShowMonthOutline: Bool? { localStorage.object(forKey: Prefs.showMonthOutline) as? Bool }

    override func setUp() {

        localStorage.reset()

        XCTAssertNil(localStorageStatusItemIconEnabled)
        XCTAssertNil(localStorageStatusItemDateEnabled)
        XCTAssertNil(localStorageStatusItemBackgroundEnabled)
        XCTAssertNil(localStorageStatusItemDateStyle)
        XCTAssertNil(localStorageStatusItemTextScaling)
        XCTAssertNil(localStorageShowEventStatusItem)
        XCTAssertNil(localStorageEventStatusItemCheckRange)
        XCTAssertNil(localStorageEventStatusItemTextScaling)
        XCTAssertNil(localStorageEventStatusItemLength)
        XCTAssertNil(localStorageEventStatusItemDetectNotch)
        XCTAssertNil(localStorageCalendarScaling)
        XCTAssertNil(localStorageFirstWeekday)
        XCTAssertNil(localStorageHighlightedWeekdays)
        XCTAssertNil(localStorageShowWeekNumbers)
        XCTAssertNil(localStorageShowDeclinedEvents)
        XCTAssertNil(localStoragePreserveSelectedDate)
        XCTAssertNil(localStorageShowMap)
        XCTAssertNil(localStorageShowPastEvents)
        XCTAssertNil(localStorageShowOverdueReminders)
        XCTAssertNil(localStorageShowAllDayDetails)
        XCTAssertNil(localStorageShowRecurrenceIndicator)
        XCTAssertNil(localStorageShowEventListSummary)
        XCTAssertNil(localStorageTransparency)
        XCTAssertNil(localStorageEventDotsStyle)
        XCTAssertNil(localStorageFutureEventsDays)
        XCTAssertNil(localStorageShowMonthOutline)

        registerDefaultPrefs(in: localStorage, calendar: .gregorian.with(firstWeekday: 3))
    }

    func testDefaultSettings() {

        XCTAssertEqual(viewModel.showStatusItemIcon.lastValue(), true)
        XCTAssertEqual(viewModel.showStatusItemDate.lastValue(), true)
        XCTAssertEqual(viewModel.showStatusItemBackground.lastValue(), false)
        XCTAssertEqual(viewModel.statusItemDateStyle.lastValue(), .short)
        XCTAssertEqual(viewModel.statusItemTextScaling.lastValue(), 1.2)
        XCTAssertEqual(viewModel.showEventStatusItem.lastValue(), false)
        XCTAssertEqual(viewModel.eventStatusItemTextScaling.lastValue(), 1.2)
        XCTAssertEqual(viewModel.eventStatusItemCheckRange.lastValue(), 6)
        XCTAssertEqual(viewModel.eventStatusItemLength.lastValue(), 18)
        XCTAssertEqual(viewModel.eventStatusItemDetectNotch.lastValue(), false)
        XCTAssertEqual(viewModel.calendarScaling.lastValue(), 1)
        XCTAssertEqual(viewModel.firstWeekday.lastValue(), 3)
        XCTAssertEqual(viewModel.highlightedWeekdays.lastValue(), [0, 6])
        XCTAssertEqual(viewModel.showWeekNumbers.lastValue(), false)
        XCTAssertEqual(viewModel.showDeclinedEvents.lastValue(), false)
        XCTAssertEqual(viewModel.preserveSelectedDate.lastValue(), false)
        XCTAssertEqual(viewModel.showMap.lastValue(), true)
        XCTAssertEqual(viewModel.showPastEvents.lastValue(), true)
        XCTAssertEqual(viewModel.showOverdueReminders.lastValue(), true)
        XCTAssertEqual(viewModel.showAllDayDetails.lastValue(), true)
        XCTAssertEqual(viewModel.showRecurrenceIndicator.lastValue(), true)
        XCTAssertEqual(viewModel.showEventListSummary.lastValue(), true)
        XCTAssertEqual(viewModel.popoverTransparency.lastValue(), 2)
        XCTAssertEqual(viewModel.popoverMaterial.lastValue(), .headerView)
        XCTAssertEqual(viewModel.appearanceMode.lastValue(), .automatic)
        XCTAssertEqual(viewModel.eventDotsStyle.lastValue(), .multiple)
        XCTAssertEqual(viewModel.futureEventsDays.lastValue(), 0)
        XCTAssertEqual(viewModel.showMonthOutline.lastValue(), true)

        XCTAssertEqual(localStorageStatusItemIconEnabled, true)
        XCTAssertEqual(localStorageStatusItemDateEnabled, true)
        XCTAssertEqual(localStorageStatusItemBackgroundEnabled, false)
        XCTAssertEqual(localStorageStatusItemTextScaling, 1.2)
        XCTAssertEqual(localStorageStatusItemDateStyle, 1)
        XCTAssertEqual(localStorageShowEventStatusItem, false)
        XCTAssertEqual(localStorageEventStatusItemTextScaling, 1.2)
        XCTAssertEqual(localStorageEventStatusItemCheckRange, 6)
        XCTAssertEqual(localStorageEventStatusItemLength, 18)
        XCTAssertEqual(localStorageEventStatusItemDetectNotch, false)
        XCTAssertEqual(localStorageCalendarScaling, 1)
        XCTAssertEqual(localStorageFirstWeekday, 3)
        XCTAssertEqual(localStorageHighlightedWeekdays, [0, 6])
        XCTAssertEqual(localStorageShowWeekNumbers, false)
        XCTAssertEqual(localStorageShowDeclinedEvents, false)
        XCTAssertEqual(localStoragePreserveSelectedDate, false)
        XCTAssertEqual(localStorageShowMap, true)
        XCTAssertEqual(localStorageShowPastEvents, true)
        XCTAssertEqual(localStorageShowOverdueReminders, true)
        XCTAssertEqual(localStorageShowRecurrenceIndicator, true)
        XCTAssertEqual(localStorageShowEventListSummary, true)
        XCTAssertEqual(localStorageTransparency, 2)
        XCTAssertEqual(localStorageAppearanceMode, 0)
        XCTAssertEqual(localStorageEventDotsStyle, EventDotsStyle.multiple.rawValue)
        XCTAssertEqual(localStorageFutureEventsDays, 0)
        XCTAssertEqual(localStorageShowMonthOutline, true)
    }

    func testDateFormatOptions() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let options = viewModel.dateFormatOptions.lastValue()

        XCTAssertEqual(options, [
            .init(style: .short, title: "1/1/21"),
            .init(style: .medium, title: "Jan 1, 2021"),
            .init(style: .long, title: "January 1, 2021"),
            .init(style: .full, title: "Friday, January 1, 2021"),
            .init(style: .none, title: "Custom")
        ])
    }

    func testDateFormatOptions_withLocaleChange() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        var options: [SettingsViewModel.DateFormatOption]?

        viewModel.dateFormatOptions
            .bind { options = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(options?.first, .init(style: .short, title: "1/1/21"))

        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")

        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(options?.first, .init(style: .short, title: "01/01/2021"))
    }

    func testEventDotsStyle() {
        localStorage.eventDotsStyle = EventDotsStyle.single_neutral.rawValue
        XCTAssertEqual(localStorageEventDotsStyle, EventDotsStyle.single_neutral.rawValue)

        var eventDotsStyle: EventDotsStyle?

        viewModel.eventDotsStyle
            .bind { eventDotsStyle = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventDotsStyle, .single_neutral)

        viewModel.eventDotsStyleObserver.onNext(.single_highlighted)

        XCTAssertEqual(eventDotsStyle, .single_highlighted)
        XCTAssertEqual(localStorageEventDotsStyle, EventDotsStyle.single_highlighted.rawValue)
    }

    func testCalendarAppViewModeOptions_pt() {

        dateProvider.m_calendar.locale = Locale(identifier: "pt")

        XCTAssertEqual(viewModel.calendarAppViewModeOptions.map(\.title), ["mês", "semana", "dia"])
    }

    func testCalendarAppViewModeOptions_de() {

        dateProvider.m_calendar.locale = Locale(identifier: "de")

        XCTAssertEqual(viewModel.calendarAppViewModeOptions.map(\.title), ["Monat", "Woche", "Tag"])
    }

    func testDateStyleSelected() {

        localStorage.statusItemDateStyle = 1
        XCTAssertEqual(localStorageStatusItemDateStyle, 1)

        var statusItemDateStyle: StatusItemDateStyle?

        viewModel.statusItemDateStyle
            .bind { statusItemDateStyle = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyleObserver.onNext(.medium)

        XCTAssertEqual(statusItemDateStyle, .medium)
        XCTAssertEqual(localStorageStatusItemDateStyle, 2)
    }

    func testCustomDateStyleSelected() throws {

        localStorage.statusItemDateStyle = 0
        XCTAssertEqual(localStorageStatusItemDateStyle, 0)

        var isDateFormatInputVisible: Bool?

        viewModel.isDateFormatInputVisible
            .bind { isDateFormatInputVisible = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(isDateFormatInputVisible, true)

        viewModel.statusItemDateStyleObserver.onNext(.short)
        XCTAssertEqual(isDateFormatInputVisible, false)

        // this should fail, but it doesn't, so we test it ¯\_(ツ)_/¯
        viewModel.statusItemDateStyleObserver.onNext(try XCTUnwrap(.init(rawValue: 5)))
        XCTAssertEqual(isDateFormatInputVisible, true)

        viewModel.statusItemDateStyleObserver.onNext(.full)
        XCTAssertEqual(isDateFormatInputVisible, false)

        viewModel.statusItemDateStyleObserver.onNext(.none)
        XCTAssertEqual(isDateFormatInputVisible, true)
    }

    func testToggleAutoLaunch() {

        var autoLaunch: Bool?

        viewModel.autoLaunch
            .bind { autoLaunch = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(autoLaunch, false)
        XCTAssertEqual(autoLauncher.isEnabled, false)

        viewModel.toggleAutoLaunch.onNext(true)

        XCTAssertEqual(autoLaunch, true)
        XCTAssertEqual(autoLauncher.isEnabled, true)
    }

    func testToggleShowEventStatusItem() {

        localStorage.showEventStatusItem = true

        var showEventStatusItem: Bool?

        viewModel.showEventStatusItem
            .bind { showEventStatusItem = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showEventStatusItem, true)
        XCTAssertEqual(localStorageShowEventStatusItem, true)

        viewModel.toggleEventStatusItem.onNext(false)

        XCTAssertEqual(showEventStatusItem, false)
        XCTAssertEqual(localStorageShowEventStatusItem, false)

        viewModel.toggleEventStatusItem.onNext(true)

        XCTAssertEqual(showEventStatusItem, true)
        XCTAssertEqual(localStorageShowEventStatusItem, true)
    }

    func testChangeEventStatusItemLength() {

        localStorage.eventStatusItemLength = 20

        var eventStatusItemLength: Int?

        viewModel.eventStatusItemLength
            .bind { eventStatusItemLength = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemLength, 20)
        XCTAssertEqual(localStorageEventStatusItemLength, 20)

        viewModel.eventStatusItemLengthObserver.onNext(30)

        XCTAssertEqual(eventStatusItemLength, 30)
        XCTAssertEqual(localStorageEventStatusItemLength, 30)
    }

    func testChangeEventStatusItemCheckRange() {

        localStorage.eventStatusItemCheckRange = 12

        var eventStatusItemCheckRange: Int?
        var eventStatusItemCheckRangeLabel: String?

        viewModel.eventStatusItemCheckRange
            .bind { eventStatusItemCheckRange = $0 }
            .disposed(by: disposeBag)

        viewModel.eventStatusItemCheckRangeLabel
            .bind { eventStatusItemCheckRangeLabel = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemCheckRange, 12)
        XCTAssertEqual(eventStatusItemCheckRangeLabel, "in 12 hours")
        XCTAssertEqual(localStorageEventStatusItemCheckRange, 12)

        viewModel.eventStatusItemCheckRangeObserver.onNext(18)

        XCTAssertEqual(eventStatusItemCheckRange, 18)
        XCTAssertEqual(eventStatusItemCheckRangeLabel, "in 18 hours")
        XCTAssertEqual(localStorageEventStatusItemCheckRange, 18)
    }

    func testEventStatusItemCheckRangeZero_shouldDisplay30min() {

        viewModel.eventStatusItemCheckRangeObserver.onNext(0)

        XCTAssertEqual(viewModel.eventStatusItemCheckRange.lastValue(), 0)
        XCTAssertEqual(viewModel.eventStatusItemCheckRangeLabel.lastValue(), "in 30 minutes")
        XCTAssertEqual(localStorageEventStatusItemCheckRange, 0)
    }

    func testToggleEventStatusItemDetectNotch() {

        localStorage.eventStatusItemDetectNotch = true

        var eventStatusItemDetectNotch: Bool?

        viewModel.eventStatusItemDetectNotch
            .bind { eventStatusItemDetectNotch = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemDetectNotch, true)
        XCTAssertEqual(localStorageEventStatusItemDetectNotch, true)

        viewModel.toggleEventStatusItemDetectNotch.onNext(false)

        XCTAssertEqual(eventStatusItemDetectNotch, false)
        XCTAssertEqual(localStorageEventStatusItemDetectNotch, false)

        viewModel.toggleEventStatusItemDetectNotch.onNext(true)

        XCTAssertEqual(eventStatusItemDetectNotch, true)
        XCTAssertEqual(localStorageEventStatusItemDetectNotch, true)
    }

    func testChangeCalendarScaling() {

        localStorage.calendarScaling = 1.2

        var calendarScaling: Double?

        viewModel.calendarScaling
            .bind { calendarScaling = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(calendarScaling, 1.2)
        XCTAssertEqual(localStorageCalendarScaling, 1.2)

        viewModel.calendarScalingObserver.onNext(1.1)

        XCTAssertEqual(calendarScaling, 1.1)
        XCTAssertEqual(localStorageCalendarScaling, 1.1)
    }

    func testChangeFirstWeekday() {

        localStorage.firstWeekday = 1

        var firstWeekday: Int?

        viewModel.firstWeekday
            .bind { firstWeekday = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(firstWeekday, 1)
        XCTAssertEqual(localStorageFirstWeekday, 1)

        viewModel.firstWeekdayNextObserver.onNext(())

        XCTAssertEqual(firstWeekday, 2)
        XCTAssertEqual(localStorageFirstWeekday, 2)

        localStorage.firstWeekday = 7

        viewModel.firstWeekdayNextObserver.onNext(())

        XCTAssertEqual(firstWeekday, 1)
        XCTAssertEqual(localStorageFirstWeekday, 1)

        viewModel.firstWeekdayPrevObserver.onNext(())

        XCTAssertEqual(firstWeekday, 7)
        XCTAssertEqual(localStorageFirstWeekday, 7)
    }

    func testChangeHighlightedWeekdays() {

        localStorage.highlightedWeekdays = []

        var highlightedWeekdays: [Int]?

        viewModel.highlightedWeekdays
            .bind { highlightedWeekdays = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(highlightedWeekdays, [])
        XCTAssertEqual(localStorageHighlightedWeekdays, [])

        viewModel.toggleHighlightedWeekday.onNext(1)

        XCTAssertEqual(highlightedWeekdays, [1])
        XCTAssertEqual(localStorageHighlightedWeekdays, [1])

        viewModel.toggleHighlightedWeekday.onNext(2)

        XCTAssertEqual(highlightedWeekdays, [1, 2])
        XCTAssertEqual(localStorageHighlightedWeekdays, [1, 2])

        viewModel.toggleHighlightedWeekday.onNext(2)

        XCTAssertEqual(highlightedWeekdays, [1])
        XCTAssertEqual(localStorageHighlightedWeekdays, [1])
    }

    func testToggleShowWeekNumbers() {

        localStorage.showWeekNumbers = true

        var showWeekNumbers: Bool?

        viewModel.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showWeekNumbers, true)
        XCTAssertEqual(localStorageShowWeekNumbers, true)

        viewModel.toggleWeekNumbers.onNext(false)

        XCTAssertEqual(showWeekNumbers, false)
        XCTAssertEqual(localStorageShowWeekNumbers, false)

        viewModel.toggleWeekNumbers.onNext(true)

        XCTAssertEqual(showWeekNumbers, true)
        XCTAssertEqual(localStorageShowWeekNumbers, true)
    }

    func testToggleShowDeclinedEvents() {

        localStorage.showDeclinedEvents = true

        var showDeclinedEvents: Bool?

        viewModel.showDeclinedEvents
            .bind { showDeclinedEvents = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showDeclinedEvents, true)
        XCTAssertEqual(localStorageShowDeclinedEvents, true)

        viewModel.toggleDeclinedEvents.onNext(false)

        XCTAssertEqual(showDeclinedEvents, false)
        XCTAssertEqual(localStorageShowDeclinedEvents, false)

        viewModel.toggleDeclinedEvents.onNext(true)

        XCTAssertEqual(showDeclinedEvents, true)
        XCTAssertEqual(localStorageShowDeclinedEvents, true)
    }

    func testTogglePreserveSelectedDate() {

        localStorage.preserveSelectedDate = true

        var preserveSelectedDate: Bool?

        viewModel.preserveSelectedDate
            .bind { preserveSelectedDate = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(preserveSelectedDate, true)
        XCTAssertEqual(localStoragePreserveSelectedDate, true)

        viewModel.togglePreserveSelectedDate.onNext(false)

        XCTAssertEqual(preserveSelectedDate, false)
        XCTAssertEqual(localStoragePreserveSelectedDate, false)

        viewModel.togglePreserveSelectedDate.onNext(true)

        XCTAssertEqual(preserveSelectedDate, true)
        XCTAssertEqual(localStoragePreserveSelectedDate, true)
    }

    func testToggleShowMap() {

        localStorage.showMap = false

        var showMap: Bool?

        viewModel.showMap
            .bind { showMap = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showMap, false)
        XCTAssertEqual(localStorageShowMap, false)

        viewModel.toggleMap.onNext(true)

        XCTAssertEqual(showMap, true)
        XCTAssertEqual(localStorageShowMap, true)

        viewModel.toggleMap.onNext(false)

        XCTAssertEqual(showMap, false)
        XCTAssertEqual(localStorageShowMap, false)
    }

    func testToggleShowPastEvents() {

        localStorage.showPastEvents = false

        var showPastEvents: Bool?

        viewModel.showPastEvents
            .bind { showPastEvents = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(localStorageShowPastEvents, false)

        viewModel.togglePastEvents.onNext(true)

        XCTAssertEqual(showPastEvents, true)
        XCTAssertEqual(localStorageShowPastEvents, true)

        viewModel.togglePastEvents.onNext(false)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(localStorageShowPastEvents, false)
    }

    func testToggleShowOverdueReminders() {

        localStorage.showOverdueReminders = false

        var showOverdueReminders: Bool?

        viewModel.showOverdueReminders
            .bind { showOverdueReminders = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showOverdueReminders, false)
        XCTAssertEqual(localStorageShowOverdueReminders, false)

        viewModel.toggleOverdueReminders.onNext(true)

        XCTAssertEqual(showOverdueReminders, true)
        XCTAssertEqual(localStorageShowOverdueReminders, true)

        viewModel.toggleOverdueReminders.onNext(false)

        XCTAssertEqual(showOverdueReminders, false)
        XCTAssertEqual(localStorageShowOverdueReminders, false)
    }

    func testToggleShowAllDayDetails() {

        localStorage.showAllDayDetails = false

        var showAllDayDetails: Bool?

        viewModel.showAllDayDetails
            .bind { showAllDayDetails = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showAllDayDetails, false)
        XCTAssertEqual(localStorageShowAllDayDetails, false)

        viewModel.toggleAllDayDetails.onNext(true)

        XCTAssertEqual(showAllDayDetails, true)
        XCTAssertEqual(localStorageShowAllDayDetails, true)

        viewModel.toggleAllDayDetails.onNext(false)

        XCTAssertEqual(showAllDayDetails, false)
        XCTAssertEqual(localStorageShowAllDayDetails, false)
    }

    func testToggleShowRecurrenceIndicator() {

        localStorage.showRecurrenceIndicator = false

        var showRecurrenceIndicator: Bool?

        viewModel.showRecurrenceIndicator
            .bind { showRecurrenceIndicator = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showRecurrenceIndicator, false)
        XCTAssertEqual(localStorageShowRecurrenceIndicator, false)

        viewModel.toggleRecurrenceIndicator.onNext(true)

        XCTAssertEqual(showRecurrenceIndicator, true)
        XCTAssertEqual(localStorageShowRecurrenceIndicator, true)

        viewModel.toggleRecurrenceIndicator.onNext(false)

        XCTAssertEqual(showRecurrenceIndicator, false)
        XCTAssertEqual(localStorageShowRecurrenceIndicator, false)
    }

    func testToggleShowEventListSummary() {

        localStorage.showEventListSummary = false

        var showEventListSummary: Bool?

        viewModel.showEventListSummary
            .bind { showEventListSummary = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showEventListSummary, false)
        XCTAssertEqual(localStorageShowEventListSummary, false)

        viewModel.toggleEventListSummary.onNext(true)

        XCTAssertEqual(showEventListSummary, true)
        XCTAssertEqual(localStorageShowEventListSummary, true)

        viewModel.toggleEventListSummary.onNext(false)

        XCTAssertEqual(showEventListSummary, false)
        XCTAssertEqual(localStorageShowEventListSummary, false)
    }

    func testChangeTransparency() {

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

        XCTAssertEqual(popoverTransparency, 5)
        XCTAssertEqual(localStorageTransparency, 5)
        XCTAssertEqual(popoverMaterial, expected[5])

        for level in 0..<expected.count {

            viewModel.transparencyObserver.onNext(level)

            XCTAssertEqual(popoverTransparency, level)
            XCTAssertEqual(localStorageTransparency?.intValue, level)
            XCTAssertEqual(popoverMaterial, expected[level])
        }
    }

    func testToggleStatusItemIcon() {

        localStorage.statusItemIconEnabled = false

        var statusItemIconEnabled: Bool?

        viewModel.showStatusItemIcon
            .bind { statusItemIconEnabled = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(statusItemIconEnabled, false)
        XCTAssertEqual(localStorageStatusItemIconEnabled, false)

        viewModel.toggleStatusItemIcon.onNext(true)

        XCTAssertEqual(statusItemIconEnabled, true)
        XCTAssertEqual(localStorageStatusItemIconEnabled, true)

        viewModel.toggleStatusItemIcon.onNext(false)

        XCTAssertEqual(statusItemIconEnabled, false)
        XCTAssertEqual(localStorageStatusItemIconEnabled, false)
    }

    func testToggleStatusItemDate() {

        localStorage.statusItemDateEnabled = false

        var statusItemDateEnabled: Bool?

        viewModel.showStatusItemDate
            .bind { statusItemDateEnabled = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(statusItemDateEnabled, false)
        XCTAssertEqual(localStorageStatusItemDateEnabled, false)

        viewModel.toggleStatusItemDate.onNext(true)

        XCTAssertEqual(statusItemDateEnabled, true)
        XCTAssertEqual(localStorageStatusItemDateEnabled, true)

        viewModel.toggleStatusItemDate.onNext(false)

        XCTAssertEqual(statusItemDateEnabled, false)
        XCTAssertEqual(localStorageStatusItemDateEnabled, false)
    }

    func testToggleShowStatusItemBackground() {

        localStorage.statusItemBackgroundEnabled = true

        var showBackground: Bool?

        viewModel.showStatusItemBackground
            .bind { showBackground = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showBackground, true)
        XCTAssertEqual(localStorageStatusItemBackgroundEnabled, true)

        viewModel.toggleStatusItemBackground.onNext(false)

        XCTAssertEqual(showBackground, false)
        XCTAssertEqual(localStorageStatusItemBackgroundEnabled, false)

        viewModel.toggleStatusItemBackground.onNext(true)

        XCTAssertEqual(showBackground, true)
        XCTAssertEqual(localStorageStatusItemBackgroundEnabled, true)
    }

    func testChangeAppearance() {

        for mode in AppearanceMode.allCases {
            viewModel.appearanceModeObserver.onNext(mode)

            XCTAssertEqual(viewModel.appearanceMode.lastValue(), mode)
            XCTAssertEqual(localStorageAppearanceMode?.intValue, mode.rawValue)
        }
    }

    func testChangeFutureEventsDays() {

        localStorage.futureEventsDays = 1

        var futureEventsDays: Int?
        var futureEventsStepperLabel: String?

        viewModel.futureEventsDays
            .bind { futureEventsDays = $0 }
            .disposed(by: disposeBag)

        viewModel.futureEventsStepperLabel
            .bind { futureEventsStepperLabel = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(futureEventsDays, 1)
        XCTAssertEqual(futureEventsStepperLabel, "in 1 day")
        XCTAssertEqual(localStorageFutureEventsDays, 1)

        viewModel.futureEventsDaysObserver.onNext(5)

        XCTAssertEqual(futureEventsDays, 5)
        XCTAssertEqual(futureEventsStepperLabel, "in 5 days")
        XCTAssertEqual(localStorageFutureEventsDays, 5)
    }

    func testToggleShowMonthOutline() {

        localStorage.showMonthOutline = true

        var showMonthOutline: Bool?

        viewModel.showMonthOutline
            .bind { showMonthOutline = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showMonthOutline, true)
        XCTAssertEqual(localStorageShowMonthOutline, true)

        viewModel.toggleMonthOutline.onNext(false)

        XCTAssertEqual(showMonthOutline, false)
        XCTAssertEqual(localStorageShowMonthOutline, false)

        viewModel.toggleMonthOutline.onNext(true)

        XCTAssertEqual(showMonthOutline, true)
        XCTAssertEqual(localStorageShowMonthOutline, true)
    }
}
