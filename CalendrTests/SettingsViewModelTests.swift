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

    let userDefaults = UserDefaults(suiteName: className())!

    lazy var viewModel = SettingsViewModel(userDefaults: userDefaults)

    var userDefaultsIconEnabled: Bool? {
        get { userDefaults.object(forKey: Prefs.statusItemIconEnabled) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.statusItemIconEnabled) }
    }

    var userDefaultsDateEnabled: Bool? {
        get { userDefaults.object(forKey: Prefs.statusItemDateEnabled) as! Bool? }
        set { userDefaults.setValue(newValue, forKey: Prefs.statusItemDateEnabled) }
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: className)
    }

    func testDefaultSettings() {

        XCTAssertNil(userDefaultsIconEnabled)
        XCTAssertNil(userDefaultsDateEnabled)

        var settings: StatusItemSettings?

        viewModel.statusItemSettings
            .bind { settings = $0 }
            .disposed(by: disposeBag)

        XCTAssertEqual(settings?.showIcon, true)
        XCTAssertEqual(settings?.showDate, false)

        XCTAssertEqual(userDefaultsIconEnabled, true)
        XCTAssertEqual(userDefaultsDateEnabled, false)
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
