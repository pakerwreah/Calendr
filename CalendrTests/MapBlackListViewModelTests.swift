//
//  MapBlackListViewModelTests.swift
//  Calendr
//
//  Created by Paker on 29/10/2025.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class MapBlackListViewModelTests {

    let localStorage = MockLocalStorageProvider()
    let scheduler = HistoricalScheduler()

    func makeViewModel() -> GenericMapBlackListViewModel<IntIDProvider> {
        .init(localStorage: localStorage, idProvider: IntIDProvider(), scheduler: scheduler)
    }

    @Test func testViewModel_initialState() {

        registerDefaultPrefs(in: localStorage)

        let viewModel = makeViewModel()

        #expect(viewModel.items == [
            .init(id: 1, text: "Microsoft Teams"),
            .init(id: 2, text: "Google Meet"),
            .init(id: 3, text: "Discord"),
            .init(id: 4, text: "Slack"),
            .init(id: 5, text: "Zoom"),
        ])
        #expect(viewModel.selection.isEmpty)
        #expect(viewModel.canRemove == false)
    }

    @Test func testViewModel_withSelection_canRemoveItems() {

        let viewModel = makeViewModel()

        #expect(viewModel.canRemove == false)
        viewModel.selection = [1]
        #expect(viewModel.canRemove)
    }

    @Test func testViewModel_removeSelected() {

        let viewModel = makeViewModel()

        viewModel.items = (1...4).map {
            .init(id: $0, text: "Test \($0)")
        }

        viewModel.selection = [1, 3]
        viewModel.removeSelected()

        #expect(viewModel.canRemove == false)
        #expect(viewModel.items.map(\.id) == [2, 4])
        #expect(localStorage.showMapBlacklistItems == ["Test 2", "Test 4"])
    }

    @Test func testViewModel_newItems() {

        let viewModel = makeViewModel()

        #expect(viewModel.items.isEmpty)

        #expect(viewModel.newItem() == 1)
        #expect(viewModel.selection == [1])
        #expect(viewModel.items == [.init(id: 1, text: .newItemText)])
        #expect(localStorage.showMapBlacklistItems.isEmpty)

        #expect(viewModel.newItem() == 2)
        #expect(viewModel.selection == [2])
        #expect(viewModel.items == [.init(id: 1, text: .newItemText), .init(id: 2, text: .newItemText)])
        #expect(localStorage.showMapBlacklistItems.isEmpty)

        viewModel.items[0].text = "Edited Item"
        viewModel.save()

        #expect(localStorage.showMapBlacklistItems == ["Edited Item", .newItemText])
    }

    @Test func testViewModel_loadsExistingRegex() {

        localStorage.showMapBlacklistRegex = "([A-Z0-9]+\\-){5}.+"

        let viewModel = makeViewModel()

        #expect(viewModel.regexText == "([A-Z0-9]+\\-){5}.+")
        #expect(viewModel.isRegexInvalid == false)
        #expect(viewModel.isRegexVisible)
    }

    @Test func testViewModel_noRegex_defaultsToEmptyAndValid() {

        let viewModel = makeViewModel()

        #expect(viewModel.regexText.isEmpty)
        #expect(viewModel.isRegexInvalid == false)
        #expect(viewModel.isRegexVisible == false)
    }

    @Test func testViewModel_blankRegex_defaultsToHidden() {

        localStorage.showMapBlacklistRegex = "   "

        let viewModel = makeViewModel()

        #expect(viewModel.isRegexVisible == false)
    }

    @Test func testViewModel_regexTyping_isNotFlaggedInvalidBeforeDebounce() {

        let viewModel = makeViewModel()

        viewModel.regexText = "("

        #expect(viewModel.isRegexInvalid == false)
    }

    @Test func testViewModel_regexTyping_debouncedInvalidState() {

        let viewModel = makeViewModel()

        viewModel.regexText = "("

        scheduler.advance(.milliseconds(299))
        #expect(viewModel.isRegexInvalid == false)

        scheduler.advance(.milliseconds(1))
        #expect(viewModel.isRegexInvalid)
    }

    @Test func testViewModel_regexTyping_debouncedValidState() {

        let viewModel = makeViewModel()

        viewModel.regexText = "("
        scheduler.advance(.milliseconds(300))
        #expect(viewModel.isRegexInvalid)

        viewModel.regexText = "[A-Z]+"
        scheduler.advance(.milliseconds(300))
        #expect(viewModel.isRegexInvalid == false)
    }

    @Test func testViewModel_save_validRegex_isPersistedImmediately() {

        let viewModel = makeViewModel()

        viewModel.regexText = "[A-Z]+"
        viewModel.save()

        #expect(viewModel.isRegexInvalid == false)
        #expect(localStorage.showMapBlacklistRegex == "[A-Z]+")
    }

    @Test func testViewModel_save_invalidRegex_isNotPersisted() {

        localStorage.showMapBlacklistRegex = "[A-Z]+"

        let viewModel = makeViewModel()

        viewModel.regexText = "("
        viewModel.save()

        #expect(viewModel.isRegexInvalid)
        #expect(localStorage.showMapBlacklistRegex == "[A-Z]+")
    }

    @Test func testViewModel_save_emptyRegex_clearsStoredValue() {

        localStorage.showMapBlacklistRegex = "[A-Z]+"

        let viewModel = makeViewModel()

        viewModel.regexText = ""
        viewModel.save()

        #expect(viewModel.isRegexInvalid == false)
        #expect(localStorage.showMapBlacklistRegex == nil)
    }
}

private extension String {

    static let newItemText = Strings.MapBlackList.newItemText
}
