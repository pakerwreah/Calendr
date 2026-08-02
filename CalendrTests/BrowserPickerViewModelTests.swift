//
//  BrowserPickerViewModelTests.swift
//  Calendr
//
//  Created by Paker on 02/08/2026.
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

class BrowserPickerViewModelTests {

    let localStorage = MockLocalStorageProvider()
    lazy var workspace = MockWorkspaceServiceProvider(localStorage: localStorage)

    let disposeBag = DisposeBag()

    @Test func testBrowserOptions() {

        mockBrowsers()

        #expect(workspace.urlForDefaultBrowserApplication() == mockAppUrl("Default"))

        let urlsForBrowsers = workspace.urlsForBrowsersApplications()

        let expectedURLs = [mockAppUrl("Browser 2"), mockAppUrl("Browser 1"), mockAppUrl("Default"), mockAppUrl("Browser 3")]

        #expect(urlsForBrowsers.count == 4)
        #expect(expectedURLs.allSatisfy(urlsForBrowsers.contains))

        let viewModel = mockViewModel()

        let sortedBrowserNames = viewModel.options.map(\.name)

        #expect(sortedBrowserNames == ["Default", "Browser 1", "Browser 2", "Browser 3"])
    }

    @Test func testSystemDefaultBrowserRemovesOverride() {

        localStorage.defaultBrowserPerCalendar = ["calendar": "browser"]

        let viewModel = mockViewModel(calendarId: "calendar")

        viewModel.selectedIndexObserver.onNext(0)

        #expect(localStorage.defaultBrowserPerCalendar == [:])
    }

    @Test func testControlImageOnly() {
        #expect(mockViewModel(source: .settings).controlShowImageOnly == false)
        #expect(mockViewModel(source: .event).controlShowImageOnly == true)
    }

    @Test func testControlIconVisibility_withSettingsSource() {

        mockBrowsers()

        let viewModel = mockViewModel(source: .settings)

        var controlShowIcon: Bool?

        viewModel.controlShowIcon
            .bind { controlShowIcon = $0 }
            .disposed(by: disposeBag)

        #expect(controlShowIcon == true)

        for i in 0..<viewModel.options.count {
            viewModel.selectedIndexObserver.onNext(i)
            #expect(controlShowIcon == true)
        }

        viewModel.selectedIndexObserver.onNext(0)
        #expect(controlShowIcon == true)

        #expect(localStorage.defaultBrowserPerCalendar == [:])
    }

    @Test func testControlIconVisibility_withEventSource_withInitialDefaultBrowser() {

        mockBrowsers()

        let viewModel = mockViewModel(source: .event)

        var controlShowIcon: Bool?

        viewModel.controlShowIcon
            .bind { controlShowIcon = $0 }
            .disposed(by: disposeBag)

        #expect(controlShowIcon == false)

        viewModel.selectedIndexObserver.onNext(0)
        #expect(controlShowIcon == false)

        for i in 1..<viewModel.options.count {
            viewModel.selectedIndexObserver.onNext(i)
            #expect(controlShowIcon == true)
        }

        // should no longer hide the icon
        viewModel.selectedIndexObserver.onNext(0)
        #expect(controlShowIcon == true)

        #expect(localStorage.defaultBrowserPerCalendar == [:])
    }

    @Test func testControlIconVisibility_withEventSource_withInitialCustomBrowser() {

        mockBrowsers()

        localStorage.defaultBrowserPerCalendar = ["calendar": mockAppUrl("Browser 1").absoluteString]

        let viewModel = mockViewModel(calendarId: "calendar", source: .event)

        var controlShowIcon: Bool?

        viewModel.controlShowIcon
            .bind { controlShowIcon = $0 }
            .disposed(by: disposeBag)

        #expect(controlShowIcon == true)

        for i in 0..<viewModel.options.count {
            viewModel.selectedIndexObserver.onNext(i)
            #expect(controlShowIcon == true)
        }

        // should no longer hide the icon
        viewModel.selectedIndexObserver.onNext(0)
        #expect(controlShowIcon == true)

        #expect(localStorage.defaultBrowserPerCalendar == [:])
    }

    func mockBrowsers() {
        workspace.m_urlForApplicationToOpenURL = mockAppUrl("Default")
        workspace.m_urlForApplicationToOpenContentType = mockAppUrl("Default")

        workspace.m_urlsForApplicationsToOpenURL = [mockAppUrl("Browser 2"), mockAppUrl("Browser 1"), mockAppUrl("Default"), mockAppUrl("Browser 3")]
        workspace.m_urlsForApplicationsToOpenContentType = [mockAppUrl("Browser 2"), mockAppUrl("Browser 1"), mockAppUrl("Default"), mockAppUrl("Browser 3"), mockAppUrl("Not a real browser 4")]
    }

    func mockViewModel(calendarId: String = "", source: BrowserPickerSource = .settings) -> BrowserPickerViewModel {
        BrowserPickerViewModel(
            calendarId: calendarId,
            workspace: workspace,
            localStorage: localStorage,
            source: source
        )
    }
}
