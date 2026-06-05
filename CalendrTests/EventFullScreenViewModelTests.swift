//
//  EventFullScreenViewModelTests.swift
//  Calendr
//
//  Created by Paker on 03/06/2026.
//

import XCTest
import RxSwift
@testable import Calendr

class EventFullScreenViewModelTests: XCTestCase {

    let cooldown: DispatchTimeInterval = .milliseconds(1500)

    let disposeBag = DisposeBag()

    let localStorage = MockLocalStorageProvider()
    let dateProvider = MockDateProvider()
    lazy var workspace = MockWorkspaceServiceProvider(localStorage: localStorage)
    let scheduler = HistoricalScheduler()

    var onSkip: (() -> Void)?

    override func setUp() {

        localStorage.reset()

        registerDefaultPrefs(in: localStorage)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    func testBasicInfo() {

        let viewModel = mock(
            event: .make(
                title: "Design Review",
                url: .init(string: "https://google.com"),
            ),
        )

        XCTAssertEqual(viewModel.title, "Design Review")
        XCTAssertEqual(viewModel.link?.url.absoluteString, "https://google.com")
        XCTAssertEqual(viewModel.isDismissLocked, true)
        XCTAssertEqual(viewModel.transparencyLevel, 2)
        XCTAssertEqual(viewModel.material, .regular)
    }

    func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2026, month: 1, day: 1, hour: 15),
                end: .make(year: 2026, month: 1, day: 1, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "3:00 - 4:00 PM")
    }

    func testDuration_isNotSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2026, month: 1, day: 1, hour: 15),
                end: .make(year: 2026, month: 1, day: 2, hour: 16)
            )
        )

        XCTAssertEqual(viewModel.duration, "Jan 1, 2026 at 3:00 PM - Jan 2, 2026 at 4:00 PM")
    }

    func testTransparency() {

        let viewModel = mock()

        viewModel.transparencyLevel = 0
        XCTAssertEqual(viewModel.material, .ultraThick)

        viewModel.transparencyLevel = 1
        XCTAssertEqual(viewModel.material, .thick)

        viewModel.transparencyLevel = 2
        XCTAssertEqual(viewModel.material, .regular)

        viewModel.transparencyLevel = 3
        XCTAssertEqual(viewModel.material, .thin)

        viewModel.transparencyLevel = 4
        XCTAssertEqual(viewModel.material, .ultraThin)

        // Out of bounds

        viewModel.transparencyLevel = -1
        XCTAssertEqual(viewModel.material, .ultraThick)

        viewModel.transparencyLevel = 5
        XCTAssertEqual(viewModel.material, .ultraThin)
    }

    func testDismissLock() {

        let viewModel = mock()

        viewModel.onAppear()

        XCTAssertTrue(viewModel.isDismissLocked)

        scheduler.advance(cooldown)

        XCTAssertFalse(viewModel.isDismissLocked)
    }

    func testClose_beforeCooldown_shouldNotDismiss() {

        let dismissExpectation = expectation(description: "Dismiss")
        dismissExpectation.isInverted = true

        let viewModel = mock()

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        viewModel.performClose()

        wait(for: [dismissExpectation], timeout: 0.1)
    }

    func testClose_afterCooldown_shouldDismiss() {

        let dismissExpectation = expectation(description: "Dismiss")

        let viewModel = mock()

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.performClose()

        wait(for: [dismissExpectation], timeout: 0.1)
    }

    func testSkip_beforeCooldown_shouldNotSkip() {

        let skipExpectation = expectation(description: "Skip")
        skipExpectation.isInverted = true

        let dismissExpectation = expectation(description: "Dismiss")
        dismissExpectation.isInverted = true

        let viewModel = mock()

        onSkip = skipExpectation.fulfill

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        viewModel.skip()

        wait(for: [skipExpectation, dismissExpectation], timeout: 0.1)
    }

    func testSkip_afterCooldown_shouldSkip() {

        let skipExpectation = expectation(description: "Skip")
        let dismissExpectation = expectation(description: "Dismiss")

        let viewModel = mock()

        onSkip = skipExpectation.fulfill

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.skip()

        wait(for: [skipExpectation, dismissExpectation], timeout: 0.1)
    }

    func testJoin_beforeCooldown_shouldNotJoin() {

        let joinExpectation = expectation(description: "Join")
        joinExpectation.isInverted = true

        let dismissExpectation = expectation(description: "Dismiss")
        dismissExpectation.isInverted = true

        let viewModel = mock(
            event: .make(
                url: .init(string: "https://zoom.com/j/99999")
            )
        )

        workspace.didOpenURL = { _ in
            joinExpectation.fulfill()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        viewModel.join()

        wait(for: [joinExpectation, dismissExpectation], timeout: 0.1)
    }

    func testJoin_afterCooldown_shouldJoin() {

        let joinExpectation = expectation(description: "Join")
        let dismissExpectation = expectation(description: "Dismiss")

        workspace.m_urlForApplicationToOpenURL = URL(string: "dummy")

        let viewModel = mock(
            event: .make(
                url: .init(string: "https://zoom.us/j/99999")
            )
        )

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "zoommtg://zoom.us/join?confno=99999")
            joinExpectation.fulfill()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        wait(for: [joinExpectation, dismissExpectation], timeout: 0.1)
    }

    func testJoin_shouldOpenURL() {

        let openExpectation = expectation(description: "Open")
        let dismissExpectation = expectation(description: "Dismiss")

        let viewModel = mock(
            event: .make(
                url: .init(string: "https://zoom.us/j/99999")
            )
        )

        workspace.didOpenURL = { url in
            XCTAssertEqual(url.absoluteString, "https://zoom.us/j/99999")
            openExpectation.fulfill()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        wait(for: [openExpectation, dismissExpectation], timeout: 0.1)
    }

    func testJoin_shouldOpenPreferredBrowserForCalendar() {

        let openExpectation = expectation(description: "Open")
        let dismissExpectation = expectation(description: "Dismiss")

        let httpUrl = "https://zoom.us/j/99999"
        let browserAppUrl = "/Applications/Browser.app"

        let viewModel = mock(
            event: .make(
                url: .init(string: httpUrl),
                calendar: .make(id: "1")
            )
        )

        localStorage.defaultBrowserPerCalendar = ["1": browserAppUrl]

        workspace.didOpenURLWithApplication = { url, appUrl in
            XCTAssertEqual(url.absoluteString, httpUrl)
            XCTAssertEqual(appUrl?.absoluteString, browserAppUrl)
            openExpectation.fulfill()
        }

        workspace.didOpenURL = { _ in
            XCTFail()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        wait(for: [openExpectation, dismissExpectation], timeout: 0.1)
    }

    func mock(event: EventModel = .make()) -> EventFullScreenViewModel {

        EventFullScreenViewModel(
            event: event,
            dateProvider: dateProvider,
            forceLocalTimeZone: false,
            localStorage: localStorage,
            workspace: workspace,
            scheduler: scheduler,
            onSkip: { [weak self] in
                self?.onSkip?()
            }
        )
    }
}
