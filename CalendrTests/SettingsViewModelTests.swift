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
    let userDefaults = UserDefaults(suiteName: className())!
    let notificationCenter = NotificationCenter()

    lazy var viewModel = SettingsViewModel(
        autoLauncher: autoLauncher,
        dateProvider: dateProvider,
        workspace: workspace,
        userDefaults: userDefaults,
        notificationCenter: notificationCenter
    )

    var userDefaultsStatusItemIconEnabled: Bool? { userDefaults.object(forKey: Prefs.statusItemIconEnabled) as! Bool? }
    var userDefaultsStatusItemDateEnabled: Bool? { userDefaults.object(forKey: Prefs.statusItemDateEnabled) as! Bool? }
    var userDefaultsStatusItemBackgroundEnabled: Bool? { userDefaults.object(forKey: Prefs.statusItemBackgroundEnabled) as! Bool? }
    var userDefaultsStatusItemDateStyle: Int? { userDefaults.object(forKey: Prefs.statusItemDateStyle) as! Int? }
    var userDefaultsStatusItemTextScaling: Double? { userDefaults.object(forKey: Prefs.statusItemTextScaling) as! Double? }
    var userDefaultsShowEventStatusItem: Bool? { userDefaults.object(forKey: Prefs.showEventStatusItem) as! Bool? }
    var userDefaultsEventStatusItemCheckRange: Int? { userDefaults.object(forKey: Prefs.eventStatusItemCheckRange) as! Int? }
    var userDefaultsEventStatusItemTextScaling: Double? { userDefaults.object(forKey: Prefs.eventStatusItemTextScaling) as! Double? }
    var userDefaultsEventStatusItemLength: Int? { userDefaults.object(forKey: Prefs.eventStatusItemLength) as! Int? }
    var userDefaultsEventStatusItemDetectNotch: Bool? { userDefaults.object(forKey: Prefs.eventStatusItemDetectNotch) as! Bool? }
    var userDefaultsCalendarScaling: Double? { userDefaults.object(forKey: Prefs.calendarScaling) as! Double? }
    var userDefaultsFirstWeekday: Int? { userDefaults.object(forKey: Prefs.firstWeekday) as! Int? }
    var userDefaultsHighlightedWeekdays: [Int]? { userDefaults.object(forKey: Prefs.highlightedWeekdays) as! [Int]? }
    var userDefaultsShowWeekNumbers: Bool? { userDefaults.object(forKey: Prefs.showWeekNumbers) as! Bool? }
    var userDefaultsShowDeclinedEvents: Bool? { userDefaults.object(forKey: Prefs.showDeclinedEvents) as! Bool? }
    var userDefaultsPreserveSelectedDate: Bool? { userDefaults.object(forKey: Prefs.preserveSelectedDate) as! Bool? }
    var userDefaultsShowMap: Bool? { userDefaults.object(forKey: Prefs.showMap) as! Bool? }
    var userDefaultsShowPastEvents: Bool? { userDefaults.object(forKey: Prefs.showPastEvents) as! Bool? }
    var userDefaultsShowOverdueReminders: Bool? { userDefaults.object(forKey: Prefs.showOverdueReminders) as! Bool? }
    var userDefaultsShowRecurrenceIndicator: Bool? { userDefaults.object(forKey: Prefs.showRecurrenceIndicator) as! Bool? }
    var userDefaultsTransparency: Int? { userDefaults.object(forKey: Prefs.transparencyLevel) as! Int? }
    var userDefaultsAppearanceMode: Int? { userDefaults.object(forKey: Prefs.appearanceMode) as! Int? }

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)

        XCTAssertNil(userDefaultsStatusItemIconEnabled)
        XCTAssertNil(userDefaultsStatusItemDateEnabled)
        XCTAssertNil(userDefaultsStatusItemBackgroundEnabled)
        XCTAssertNil(userDefaultsStatusItemDateStyle)
        XCTAssertNil(userDefaultsStatusItemTextScaling)
        XCTAssertNil(userDefaultsShowEventStatusItem)
        XCTAssertNil(userDefaultsEventStatusItemCheckRange)
        XCTAssertNil(userDefaultsEventStatusItemTextScaling)
        XCTAssertNil(userDefaultsEventStatusItemLength)
        XCTAssertNil(userDefaultsEventStatusItemDetectNotch)
        XCTAssertNil(userDefaultsCalendarScaling)
        XCTAssertNil(userDefaultsFirstWeekday)
        XCTAssertNil(userDefaultsHighlightedWeekdays)
        XCTAssertNil(userDefaultsShowWeekNumbers)
        XCTAssertNil(userDefaultsShowDeclinedEvents)
        XCTAssertNil(userDefaultsPreserveSelectedDate)
        XCTAssertNil(userDefaultsShowMap)
        XCTAssertNil(userDefaultsShowPastEvents)
        XCTAssertNil(userDefaultsShowOverdueReminders)
        XCTAssertNil(userDefaultsShowRecurrenceIndicator)
        XCTAssertNil(userDefaultsTransparency)

        registerDefaultPrefs(in: userDefaults, calendar: .gregorian.with(firstWeekday: 3))
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
        XCTAssertEqual(viewModel.showRecurrenceIndicator.lastValue(), true)
        XCTAssertEqual(viewModel.popoverTransparency.lastValue(), 2)
        XCTAssertEqual(viewModel.popoverMaterial.lastValue(), .headerView)
        XCTAssertEqual(viewModel.appearanceMode.lastValue(), .automatic)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, true)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, true)
        XCTAssertEqual(userDefaultsStatusItemBackgroundEnabled, false)
        XCTAssertEqual(userDefaultsStatusItemTextScaling, 1.2)
        XCTAssertEqual(userDefaultsStatusItemDateStyle, 1)
        XCTAssertEqual(userDefaultsShowEventStatusItem, false)
        XCTAssertEqual(userDefaultsEventStatusItemTextScaling, 1.2)
        XCTAssertEqual(userDefaultsEventStatusItemCheckRange, 6)
        XCTAssertEqual(userDefaultsEventStatusItemLength, 18)
        XCTAssertEqual(userDefaultsEventStatusItemDetectNotch, false)
        XCTAssertEqual(userDefaultsCalendarScaling, 1)
        XCTAssertEqual(userDefaultsFirstWeekday, 3)
        XCTAssertEqual(userDefaultsHighlightedWeekdays, [0, 6])
        XCTAssertEqual(userDefaultsShowWeekNumbers, false)
        XCTAssertEqual(userDefaultsShowDeclinedEvents, false)
        XCTAssertEqual(userDefaultsPreserveSelectedDate, false)
        XCTAssertEqual(userDefaultsShowMap, true)
        XCTAssertEqual(userDefaultsShowPastEvents, true)
        XCTAssertEqual(userDefaultsShowOverdueReminders, true)
        XCTAssertEqual(userDefaultsShowRecurrenceIndicator, true)
        XCTAssertEqual(userDefaultsTransparency, 2)
        XCTAssertEqual(userDefaultsAppearanceMode, 0)
    }

    func testDateFormatOptions() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        let options = viewModel.dateFormatOptions.lastValue()

        XCTAssertEqual(options, [
            .init(style: .short, title: "1/1/21"),
            .init(style: .medium, title: "Jan 1, 2021"),
            .init(style: .long, title: "January 1, 2021"),
            .init(style: .full, title: "Friday, January 1, 2021"),
            .init(style: .none, title: "Custom...")
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

    func testCalendarAppViewModeOptions_pt() {

        dateProvider.m_calendar.locale = Locale(identifier: "pt")

        XCTAssertEqual(viewModel.calendarAppViewModeOptions.map(\.title), ["mês", "semana", "dia"])
    }

    func testCalendarAppViewModeOptions_de() {

        dateProvider.m_calendar.locale = Locale(identifier: "de")

        XCTAssertEqual(viewModel.calendarAppViewModeOptions.map(\.title), ["Monat", "Woche", "Tag"])
    }

    func testDateStyleSelected() {

        userDefaults.statusItemDateStyle = 1
        XCTAssertEqual(userDefaultsStatusItemDateStyle, 1)

        var statusItemDateStyle: StatusItemDateStyle?

        viewModel.statusItemDateStyle
            .bind { statusItemDateStyle = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyleObserver.onNext(.medium)

        XCTAssertEqual(statusItemDateStyle, .medium)
        XCTAssertEqual(userDefaultsStatusItemDateStyle, 2)
    }

    func testCustomDateStyleSelected() throws {

        userDefaults.statusItemDateStyle = 0
        XCTAssertEqual(userDefaultsStatusItemDateStyle, 0)

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

        userDefaults.showEventStatusItem = true

        var showEventStatusItem: Bool?

        viewModel.showEventStatusItem
            .bind { showEventStatusItem = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showEventStatusItem, true)
        XCTAssertEqual(userDefaultsShowEventStatusItem, true)

        viewModel.toggleEventStatusItem.onNext(false)

        XCTAssertEqual(showEventStatusItem, false)
        XCTAssertEqual(userDefaultsShowEventStatusItem, false)

        viewModel.toggleEventStatusItem.onNext(true)

        XCTAssertEqual(showEventStatusItem, true)
        XCTAssertEqual(userDefaultsShowEventStatusItem, true)
    }

    func testChangeEventStatusItemLength() {

        userDefaults.eventStatusItemLength = 20

        var eventStatusItemLength: Int?

        viewModel.eventStatusItemLength
            .bind { eventStatusItemLength = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemLength, 20)
        XCTAssertEqual(userDefaultsEventStatusItemLength, 20)

        viewModel.eventStatusItemLengthObserver.onNext(30)

        XCTAssertEqual(eventStatusItemLength, 30)
        XCTAssertEqual(userDefaultsEventStatusItemLength, 30)
    }

    func testChangeEventStatusItemCheckRange() {

        userDefaults.eventStatusItemCheckRange = 12

        var eventStatusItemCheckRange: Int?

        viewModel.eventStatusItemCheckRange
            .bind { eventStatusItemCheckRange = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemCheckRange, 12)
        XCTAssertEqual(userDefaultsEventStatusItemCheckRange, 12)

        viewModel.eventStatusItemCheckRangeObserver.onNext(18)

        XCTAssertEqual(eventStatusItemCheckRange, 18)
        XCTAssertEqual(userDefaultsEventStatusItemCheckRange, 18)
    }

    func testToggleEventStatusItemDetectNotch() {

        userDefaults.eventStatusItemDetectNotch = true

        var eventStatusItemDetectNotch: Bool?

        viewModel.eventStatusItemDetectNotch
            .bind { eventStatusItemDetectNotch = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(eventStatusItemDetectNotch, true)
        XCTAssertEqual(userDefaultsEventStatusItemDetectNotch, true)

        viewModel.toggleEventStatusItemDetectNotch.onNext(false)

        XCTAssertEqual(eventStatusItemDetectNotch, false)
        XCTAssertEqual(userDefaultsEventStatusItemDetectNotch, false)

        viewModel.toggleEventStatusItemDetectNotch.onNext(true)

        XCTAssertEqual(eventStatusItemDetectNotch, true)
        XCTAssertEqual(userDefaultsEventStatusItemDetectNotch, true)
    }

    func testChangeCalendarScaling() {

        userDefaults.calendarScaling = 1.2

        var calendarScaling: Double?

        viewModel.calendarScaling
            .bind { calendarScaling = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(calendarScaling, 1.2)
        XCTAssertEqual(userDefaultsCalendarScaling, 1.2)

        viewModel.calendarScalingObserver.onNext(1.1)

        XCTAssertEqual(calendarScaling, 1.1)
        XCTAssertEqual(userDefaultsCalendarScaling, 1.1)
    }

    func testChangeFirstWeekday() {

        userDefaults.firstWeekday = 1

        var firstWeekday: Int?

        viewModel.firstWeekday
            .bind { firstWeekday = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(firstWeekday, 1)
        XCTAssertEqual(userDefaultsFirstWeekday, 1)

        viewModel.firstWeekdayNextObserver.onNext(())

        XCTAssertEqual(firstWeekday, 2)
        XCTAssertEqual(userDefaultsFirstWeekday, 2)

        userDefaults.firstWeekday = 7

        viewModel.firstWeekdayNextObserver.onNext(())

        XCTAssertEqual(firstWeekday, 1)
        XCTAssertEqual(userDefaultsFirstWeekday, 1)

        viewModel.firstWeekdayPrevObserver.onNext(())

        XCTAssertEqual(firstWeekday, 7)
        XCTAssertEqual(userDefaultsFirstWeekday, 7)
    }

    func testChangeHighlightedWeekdays() {

        userDefaults.highlightedWeekdays = []

        var highlightedWeekdays: [Int]?

        viewModel.highlightedWeekdays
            .bind { highlightedWeekdays = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(highlightedWeekdays, [])
        XCTAssertEqual(userDefaultsHighlightedWeekdays, [])

        viewModel.toggleHighlightedWeekday.onNext(1)

        XCTAssertEqual(highlightedWeekdays, [1])
        XCTAssertEqual(userDefaultsHighlightedWeekdays, [1])

        viewModel.toggleHighlightedWeekday.onNext(2)

        XCTAssertEqual(highlightedWeekdays, [1, 2])
        XCTAssertEqual(userDefaultsHighlightedWeekdays, [1, 2])

        viewModel.toggleHighlightedWeekday.onNext(2)

        XCTAssertEqual(highlightedWeekdays, [1])
        XCTAssertEqual(userDefaultsHighlightedWeekdays, [1])
    }

    func testToggleShowWeekNumbers() {

        userDefaults.showWeekNumbers = true

        var showWeekNumbers: Bool?

        viewModel.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showWeekNumbers, true)
        XCTAssertEqual(userDefaultsShowWeekNumbers, true)

        viewModel.toggleWeekNumbers.onNext(false)

        XCTAssertEqual(showWeekNumbers, false)
        XCTAssertEqual(userDefaultsShowWeekNumbers, false)

        viewModel.toggleWeekNumbers.onNext(true)

        XCTAssertEqual(showWeekNumbers, true)
        XCTAssertEqual(userDefaultsShowWeekNumbers, true)
    }

    func testToggleShowDeclinedEvents() {

        userDefaults.showDeclinedEvents = true

        var showDeclinedEvents: Bool?

        viewModel.showDeclinedEvents
            .bind { showDeclinedEvents = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showDeclinedEvents, true)
        XCTAssertEqual(userDefaultsShowDeclinedEvents, true)

        viewModel.toggleDeclinedEvents.onNext(false)

        XCTAssertEqual(showDeclinedEvents, false)
        XCTAssertEqual(userDefaultsShowDeclinedEvents, false)

        viewModel.toggleDeclinedEvents.onNext(true)

        XCTAssertEqual(showDeclinedEvents, true)
        XCTAssertEqual(userDefaultsShowDeclinedEvents, true)
    }

    func testTogglePreserveSelectedDate() {

        userDefaults.preserveSelectedDate = true

        var preserveSelectedDate: Bool?

        viewModel.preserveSelectedDate
            .bind { preserveSelectedDate = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(preserveSelectedDate, true)
        XCTAssertEqual(userDefaultsPreserveSelectedDate, true)

        viewModel.togglePreserveSelectedDate.onNext(false)

        XCTAssertEqual(preserveSelectedDate, false)
        XCTAssertEqual(userDefaultsPreserveSelectedDate, false)

        viewModel.togglePreserveSelectedDate.onNext(true)

        XCTAssertEqual(preserveSelectedDate, true)
        XCTAssertEqual(userDefaultsPreserveSelectedDate, true)
    }

    func testToggleShowMap() {

        userDefaults.showMap = false

        var showMap: Bool?

        viewModel.showMap
            .bind { showMap = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showMap, false)
        XCTAssertEqual(userDefaultsShowMap, false)

        viewModel.toggleMap.onNext(true)

        XCTAssertEqual(showMap, true)
        XCTAssertEqual(userDefaultsShowMap, true)

        viewModel.toggleMap.onNext(false)

        XCTAssertEqual(showMap, false)
        XCTAssertEqual(userDefaultsShowMap, false)
    }

    func testToggleShowPastEvents() {

        userDefaults.showPastEvents = false

        var showPastEvents: Bool?

        viewModel.showPastEvents
            .bind { showPastEvents = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(userDefaultsShowPastEvents, false)

        viewModel.togglePastEvents.onNext(true)

        XCTAssertEqual(showPastEvents, true)
        XCTAssertEqual(userDefaultsShowPastEvents, true)

        viewModel.togglePastEvents.onNext(false)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(userDefaultsShowPastEvents, false)
    }

    func testToggleShowOverdueReminders() {

        userDefaults.showOverdueReminders = false

        var showOverdueReminders: Bool?

        viewModel.showOverdueReminders
            .bind { showOverdueReminders = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showOverdueReminders, false)
        XCTAssertEqual(userDefaultsShowOverdueReminders, false)

        viewModel.toggleOverdueReminders.onNext(true)

        XCTAssertEqual(showOverdueReminders, true)
        XCTAssertEqual(userDefaultsShowOverdueReminders, true)

        viewModel.toggleOverdueReminders.onNext(false)

        XCTAssertEqual(showOverdueReminders, false)
        XCTAssertEqual(userDefaultsShowOverdueReminders, false)
    }

    func testToggleShowRecurrenceIndicator() {

        userDefaults.showRecurrenceIndicator = false

        var showRecurrenceIndicator: Bool?

        viewModel.showRecurrenceIndicator
            .bind { showRecurrenceIndicator = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showRecurrenceIndicator, false)
        XCTAssertEqual(userDefaultsShowRecurrenceIndicator, false)

        viewModel.toggleRecurrenceIndicator.onNext(true)

        XCTAssertEqual(showRecurrenceIndicator, true)
        XCTAssertEqual(userDefaultsShowRecurrenceIndicator, true)

        viewModel.toggleRecurrenceIndicator.onNext(false)

        XCTAssertEqual(showRecurrenceIndicator, false)
        XCTAssertEqual(userDefaultsShowRecurrenceIndicator, false)
    }

    func testChangeTransparency() {

        userDefaults.transparencyLevel = 5

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
        XCTAssertEqual(userDefaultsTransparency, 5)
        XCTAssertEqual(popoverMaterial, expected[5])

        for level in 0..<expected.count {

            viewModel.transparencyObserver.onNext(level)

            XCTAssertEqual(popoverTransparency, level)
            XCTAssertEqual(userDefaultsTransparency, level)
            XCTAssertEqual(popoverMaterial, expected[level])
        }
    }

    /// [] icon [✓] date  =  [✓] icon [✓] date
    func testToggleIconOn_withDateOn_shouldToggleIconOn() {

        userDefaults.statusItemIconEnabled = false
        userDefaults.statusItemDateEnabled = true

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(true)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, true)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, true)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [] icon [✓] date
    func testToggleIconOff_withDateOn_shouldToggleIconOff() {

        userDefaults.statusItemIconEnabled = true
        userDefaults.statusItemDateEnabled = true

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(false)

        XCTAssertEqual(showStatusItemIcon, false)
        XCTAssertEqual(showStatusItemDate, true)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, false)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, true)
    }

    /// [✓] icon [] date  =  [✓] icon [] date
    func testToggleIconOff_withDateOff_shouldDoNothing() {

        userDefaults.statusItemIconEnabled = true
        userDefaults.statusItemDateEnabled = false

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(false)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, false)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, false)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, false)
    }

    /// [✓] icon [] date  =  [✓] icon [✓] date
    func testToggleDateOn_withIconOn_shouldToggleDateOn() {

        userDefaults.statusItemIconEnabled = true
        userDefaults.statusItemDateEnabled = false

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(true)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, true)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, true)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOn_shouldToggleDateOff() {

        userDefaults.statusItemIconEnabled = true
        userDefaults.statusItemDateEnabled = true

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(false)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, false)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, true)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, false)
    }

    /// [] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOff_shouldToggleIconOn() {

        userDefaults.statusItemIconEnabled = false
        userDefaults.statusItemDateEnabled = true

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(false)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, false)

        XCTAssertEqual(userDefaultsStatusItemIconEnabled, false)
        XCTAssertEqual(userDefaultsStatusItemDateEnabled, false)
    }

    func testToggleShowStatusItemBackground() {

        userDefaults.statusItemBackgroundEnabled = true

        var showBackground: Bool?

        viewModel.showStatusItemBackground
            .bind { showBackground = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showBackground, true)
        XCTAssertEqual(userDefaultsStatusItemBackgroundEnabled, true)

        viewModel.toggleStatusItemBackground.onNext(false)

        XCTAssertEqual(showBackground, false)
        XCTAssertEqual(userDefaultsStatusItemBackgroundEnabled, false)

        viewModel.toggleStatusItemBackground.onNext(true)

        XCTAssertEqual(showBackground, true)
        XCTAssertEqual(userDefaultsStatusItemBackgroundEnabled, true)
    }

    func testChangeAppearance() {

        for mode in AppearanceMode.allCases {
            viewModel.appearanceModeObserver.onNext(mode)

            XCTAssertEqual(viewModel.appearanceMode.lastValue(), mode)
            XCTAssertEqual(userDefaultsAppearanceMode, mode.rawValue)
        }
    }
}
