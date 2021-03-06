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

    let dateProvider = MockDateProvider()

    let userDefaults = UserDefaults(suiteName: className())!

    let notificationCenter = NotificationCenter()

    lazy var viewModel = SettingsViewModel(
        dateProvider: dateProvider,
        userDefaults: userDefaults,
        notificationCenter: notificationCenter
    )

    var userDefaultsIconEnabled: Bool? {
        get { userDefaults.object(forKey: Prefs.statusItemIconEnabled) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.statusItemIconEnabled) }
    }

    var userDefaultsDateEnabled: Bool? {
        get { userDefaults.object(forKey: Prefs.statusItemDateEnabled) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.statusItemDateEnabled) }
    }

    var userDefaultsDateStyle: Int? {
        get { userDefaults.object(forKey: Prefs.statusItemDateStyle) as! Int? }
        set { userDefaults.setValue(newValue, forKey: Prefs.statusItemDateStyle) }
    }

    var userDefaultsShowEventStatusItem: Bool? {
        get { userDefaults.object(forKey: Prefs.showEventStatusItem) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.showEventStatusItem) }
    }

    var userDefaultsShowWeekNumbers: Bool? {
        get { userDefaults.object(forKey: Prefs.showWeekNumbers) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.showWeekNumbers) }
    }

    var userDefaultsShowPastEvents: Bool? {
        get { userDefaults.object(forKey: Prefs.showPastEvents) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.showPastEvents) }
    }

    var userDefaultsTransparency: Int? {
        get { userDefaults.object(forKey: Prefs.transparencyLevel) as! Int? }
        set { userDefaults.setValue(newValue, forKey: Prefs.transparencyLevel) }
    }

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testDefaultSettings() {

        XCTAssertNil(userDefaultsIconEnabled)
        XCTAssertNil(userDefaultsDateEnabled)
        XCTAssertNil(userDefaultsDateStyle)
        XCTAssertNil(userDefaultsShowEventStatusItem)
        XCTAssertNil(userDefaultsShowWeekNumbers)
        XCTAssertNil(userDefaultsShowPastEvents)
        XCTAssertNil(userDefaultsTransparency)

        var showStatusItemIcon: Bool?
        var showStatusItemDate: Bool?
        var statusItemDateStyle: DateStyle?
        var showEventStatusItem: Bool?
        var showWeekNumbers: Bool?
        var showPastEvents: Bool?
        var popoverTransparency: Int?
        var popoverMaterial: PopoverMaterial?

        viewModel.showStatusItemIcon
            .bind { showStatusItemIcon = $0 }
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind { showStatusItemDate = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyle
            .bind { statusItemDateStyle = $0 }
            .disposed(by: disposeBag)

        viewModel.showEventStatusItem
            .bind { showEventStatusItem = $0 }
            .disposed(by: disposeBag)

        viewModel.showWeekNumbers
            .bind { showWeekNumbers = $0 }
            .disposed(by: disposeBag)

        viewModel.showPastEvents
            .bind { showPastEvents = $0 }
            .disposed(by: disposeBag)

        viewModel.popoverTransparency
            .bind { popoverTransparency = $0 }
            .disposed(by: disposeBag)

        viewModel.popoverMaterial
            .bind { popoverMaterial = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showStatusItemIcon, true)
        XCTAssertEqual(showStatusItemDate, true)
        XCTAssertEqual(statusItemDateStyle, .short)
        XCTAssertEqual(showEventStatusItem, false)
        XCTAssertEqual(showWeekNumbers, false)
        XCTAssertEqual(showPastEvents, true)
        XCTAssertEqual(popoverTransparency, 2)
        XCTAssertEqual(popoverMaterial, .headerView)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
        XCTAssertEqual(userDefaultsDateStyle, 1)
        XCTAssertEqual(userDefaultsShowEventStatusItem, false)
        XCTAssertEqual(userDefaultsShowWeekNumbers, false)
        XCTAssertEqual(userDefaultsShowPastEvents, true)
        XCTAssertEqual(userDefaultsTransparency, 2)
    }

    func testDateStyleOptions() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        var options: [String]?

        viewModel.dateFormatOptions
            .bind { options = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(options, [
            "1/1/21",
            "Jan 1, 2021",
            "January 1, 2021",
            "Friday, January 1, 2021"
        ])
    }

    func testDateStyleOptions_withLocaleChange() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        var options: [String]?

        viewModel.dateFormatOptions
            .bind { options = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(options?.first, "1/1/21")

        dateProvider.m_calendar.locale = Locale(identifier: "en_GB")

        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertEqual(options?.first, "01/01/2021")
    }

    func testDateStyleSelected() {

        userDefaultsDateStyle = 2

        var statusItemDateStyle: DateStyle?

        viewModel.statusItemDateStyle
            .bind { statusItemDateStyle = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyleObserver.onNext(.medium)

        XCTAssertEqual(statusItemDateStyle, .medium)

        XCTAssertEqual(userDefaultsDateStyle, 2)
    }

    func testToggleShowEventStatusItem() {

        userDefaultsShowEventStatusItem = true

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

    func testToggleShowWeekNumbers() {

        userDefaultsShowWeekNumbers = true

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


    func testToggleShowPastEvents() {

        userDefaultsShowPastEvents = false

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

    func testChangeTransparency() {

        userDefaultsTransparency = 5

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

        userDefaultsIconEnabled = false
        userDefaultsDateEnabled = true

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

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [] icon [✓] date
    func testToggleIconOff_withDateOn_shouldToggleIconOff() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = true

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

        XCTAssertEqual(userDefaultsIconEnabled, false)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [] date  =  [✓] icon [] date
    func testToggleIconOff_withDateOff_shouldDoNothing() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = false

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

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }

    /// [✓] icon [] date  =  [✓] icon [✓] date
    func testToggleDateOn_withIconOn_shouldToggleDateOn() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = false

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

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOn_shouldToggleDateOff() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = true

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

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }

    /// [] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOff_shouldToggleIconOn() {

        userDefaultsIconEnabled = false
        userDefaultsDateEnabled = true

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

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }
}
