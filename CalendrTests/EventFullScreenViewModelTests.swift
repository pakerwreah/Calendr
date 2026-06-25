//
//  EventFullScreenViewModelTests.swift
//  Calendr
//
//  Created by Paker on 03/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventFullScreenViewModelTests {

    let cooldown: DispatchTimeInterval = .milliseconds(1500)

    let disposeBag = DisposeBag()

    let localStorage = MockLocalStorageProvider()
    let dateProvider = MockDateProvider()
    lazy var workspace = MockWorkspaceServiceProvider(localStorage: localStorage)
    let scheduler = HistoricalScheduler()

    var onSkip: (() -> Void)?

    init() {

        localStorage.reset()

        registerDefaultPrefs(in: localStorage)

        dateProvider.m_calendar.locale = Locale(identifier: "en_US")
    }

    @Test func testBasicInfo() {

        let viewModel = mock(
            event: .make(
                title: "Design Review",
                url: .init(string: "https://google.com"),
                calendar: .make(color: .red)
            ),
        )

        #expect(viewModel.title == "Design Review")
        #expect(viewModel.link?.url.absoluteString == "https://google.com")
        #expect(viewModel.barColor == .red)
        #expect(viewModel.isDismissLocked == true)
        #expect(viewModel.transparencyLevel == 2)
        #expect(viewModel.material == .regular)
        #expect(viewModel.showSkip == true)
    }

    @Test func testReminder_shouldNotAllowSkip() {

        let viewModel = mock(event: .make(type: .reminder(completed: false)))

        #expect(viewModel.showSkip == false)
    }

    @Test func testDuration_isSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2026, month: 1, day: 1, hour: 15),
                end: .make(year: 2026, month: 1, day: 1, hour: 16)
            )
        )

        #expect(viewModel.duration == "3:00 - 4:00 PM")
    }

    @Test func testDuration_isNotSameDay() {

        let viewModel = mock(
            event: .make(
                start: .make(year: 2026, month: 1, day: 1, hour: 15),
                end: .make(year: 2026, month: 1, day: 2, hour: 16)
            )
        )

        #expect(viewModel.duration == "Jan 1, 2026 at 3:00 PM - Jan 2, 2026 at 4:00 PM")
    }

    @Test func testTransparency() {

        let viewModel = mock()

        viewModel.transparencyLevel = 0
        #expect(viewModel.material == .ultraThick)

        viewModel.transparencyLevel = 1
        #expect(viewModel.material == .thick)

        viewModel.transparencyLevel = 2
        #expect(viewModel.material == .regular)

        viewModel.transparencyLevel = 3
        #expect(viewModel.material == .thin)

        viewModel.transparencyLevel = 4
        #expect(viewModel.material == .ultraThin)

        // Out of bounds

        viewModel.transparencyLevel = -1
        #expect(viewModel.material == .ultraThick)

        viewModel.transparencyLevel = 5
        #expect(viewModel.material == .ultraThin)
    }

    @Test func testDismissLock() {

        let viewModel = mock()

        viewModel.onAppear()

        #expect(viewModel.isDismissLocked)

        scheduler.advance(cooldown)

        #expect(viewModel.isDismissLocked == false)
    }

    @Test func testClose_beforeCooldown_shouldNotDismiss() async {

        let dismissExpectation = expectation(description: "Dismiss")
        dismissExpectation.isInverted = true

        let viewModel = mock()

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        viewModel.performClose()

        await fulfillment(of: [dismissExpectation])
    }

    @Test func testClose_afterCooldown_shouldDismiss() async {

        let dismissExpectation = expectation(description: "Dismiss")

        let viewModel = mock()

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.performClose()

        await fulfillment(of: [dismissExpectation])
    }

    @Test func testSkip_beforeCooldown_shouldNotSkip() async {

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

        await fulfillment(of: [skipExpectation, dismissExpectation])
    }

    @Test func testSkip_afterCooldown_shouldSkip() async {

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

        await fulfillment(of: [skipExpectation, dismissExpectation])
    }

    @Test func testJoin_beforeCooldown_shouldNotJoin() async {

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

        await fulfillment(of: [joinExpectation, dismissExpectation])
    }

    @Test func testJoin_afterCooldown_shouldJoin() async {

        let joinExpectation = expectation(description: "Join")
        let dismissExpectation = expectation(description: "Dismiss")

        workspace.m_urlForApplicationToOpenURL = URL(string: "dummy")

        let viewModel = mock(
            event: .make(
                url: .init(string: "https://zoom.us/j/99999")
            )
        )

        workspace.didOpenURL = { url in
            #expect(url.absoluteString == "zoommtg://zoom.us/join?confno=99999")
            joinExpectation.fulfill()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        await fulfillment(of: [joinExpectation, dismissExpectation])
    }

    @Test func testJoin_shouldOpenURL() async {

        let openExpectation = expectation(description: "Open")
        let dismissExpectation = expectation(description: "Dismiss")

        let viewModel = mock(
            event: .make(
                url: .init(string: "https://zoom.us/j/99999")
            )
        )

        workspace.didOpenURL = { url in
            #expect(url.absoluteString == "https://zoom.us/j/99999")
            openExpectation.fulfill()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        await fulfillment(of: [openExpectation, dismissExpectation])
    }

    @Test func testJoin_shouldOpenPreferredBrowserForCalendar() async {

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
            #expect(url.absoluteString == httpUrl)
            #expect(appUrl?.absoluteString == browserAppUrl)
            openExpectation.fulfill()
        }

        workspace.didOpenURL = { _ in
            Issue.record()
        }

        viewModel.onDismiss.bind {
            dismissExpectation.fulfill()
        }
        .disposed(by: disposeBag)

        viewModel.onAppear()

        scheduler.advance(cooldown)

        viewModel.join()

        await fulfillment(of: [openExpectation, dismissExpectation])
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
