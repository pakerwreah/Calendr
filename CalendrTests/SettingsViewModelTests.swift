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

    lazy var viewModel = SettingsViewModel(dateProvider: dateProvider, userDefaults: userDefaults)

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

    var userDefaultsTransparency: Int? {
        get { userDefaults.object(forKey: Prefs.transparencyLevel) as! Int? }
        set { userDefaults.setValue(newValue, forKey: Prefs.transparencyLevel) }
    }

    var userDefaultsShowPastEvents: Bool? {
        get { userDefaults.object(forKey: Prefs.showPastEvents) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.showPastEvents) }
    }

    override func setUp() {
        userDefaults.setVolatileDomain([:], forName: UserDefaults.registrationDomain)
        userDefaults.removePersistentDomain(forName: className)
    }

    func testDefaultSettings() {

        XCTAssertNil(userDefaultsIconEnabled)
        XCTAssertNil(userDefaultsDateEnabled)
        XCTAssertNil(userDefaultsDateStyle)
        XCTAssertNil(userDefaultsShowPastEvents)
        XCTAssertNil(userDefaultsTransparency)

        var statusItemSettings: StatusItemSettings?
        var showPastEvents: Bool?
        var popoverTransparency: Int?
        var popoverMaterial: NSVisualEffectView.Material?

        viewModel.statusItemSettings
            .bind { statusItemSettings = $0 }
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

        XCTAssertEqual(statusItemSettings?.showIcon, true)
        XCTAssertEqual(statusItemSettings?.showDate, true)
        XCTAssertEqual(statusItemSettings?.dateStyle, .short)
        XCTAssertEqual(showPastEvents, true)
        XCTAssertEqual(popoverTransparency, 2)
        XCTAssertEqual(popoverMaterial, .headerView)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
        XCTAssertEqual(userDefaultsDateStyle, 1)
        XCTAssertEqual(userDefaultsShowPastEvents, true)
        XCTAssertEqual(userDefaultsTransparency, 2)
    }

    func testDateStyleOptions() {

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")

        XCTAssertEqual(viewModel.dateFormatOptions, [
            "1/1/21",
            "Jan 1, 2021",
            "January 1, 2021",
            "Friday, January 1, 2021"
        ])
    }

    func testDateStyleSelected() {

        userDefaultsDateStyle = 2

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.statusItemDateStyleObserver.onNext(.medium)

        XCTAssertEqual(settings?.dateStyle, .medium)

        XCTAssertEqual(userDefaultsDateStyle, 2)
    }

    func testToggleShowPastEvents() {

        userDefaultsShowPastEvents = false

        var showPastEvents: Bool?

        viewModel.showPastEvents
            .bind { showPastEvents = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(userDefaultsShowPastEvents, false)

        viewModel.toggleShowPastEvents.onNext(true)

        XCTAssertEqual(showPastEvents, true)
        XCTAssertEqual(userDefaultsShowPastEvents, true)

        viewModel.toggleShowPastEvents.onNext(false)

        XCTAssertEqual(showPastEvents, false)
        XCTAssertEqual(userDefaultsShowPastEvents, false)
    }

    func testChangeTransparency() {

        userDefaultsTransparency = 5

        var popoverTransparency: Int?
        var popoverMaterial: NSVisualEffectView.Material?

        viewModel.popoverTransparency
            .bind { popoverTransparency = $0 }
            .disposed(by: disposeBag)

        viewModel.popoverMaterial
            .bind { popoverMaterial = $0 }
            .disposed(by: disposeBag)

        let expected: [NSVisualEffectView.Material] = [
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

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(true)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, true)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [] icon [✓] date
    func testToggleIconOff_withDateOn_shouldToggleIconOff() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = true

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(false)

        XCTAssertEqual(settings?.showIcon, false)
        XCTAssertEqual(settings?.showDate, true)

        XCTAssertEqual(userDefaultsIconEnabled, false)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [] date  =  [✓] icon [] date
    func testToggleIconOff_withDateOff_shouldDoNothing() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = false

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemIcon.onNext(false)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, false)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }

    /// [✓] icon [] date  =  [✓] icon [✓] date
    func testToggleDateOn_withIconOn_shouldToggleDateOn() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = false

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(true)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, true)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, true)
    }

    /// [✓] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOn_shouldToggleDateOff() {

        userDefaultsIconEnabled = true
        userDefaultsDateEnabled = true

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(false)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, false)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }

    /// [] icon [✓] date  =  [✓] icon [] date
    func testToggleDateOff_withIconOff_shouldToggleIconOn() {

        userDefaultsIconEnabled = false
        userDefaultsDateEnabled = true

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        viewModel.toggleStatusItemDate.onNext(false)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, false)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
    }
}
