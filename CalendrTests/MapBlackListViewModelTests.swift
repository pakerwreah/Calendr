//
//  MapBlackListViewModelTests.swift
//  Calendr
//
//  Created by Paker on 29/10/2025.
//

import Foundation
import Testing
@testable import Calendr

class MapBlackListViewModelTests {

    let localStorage = MockLocalStorageProvider()

    func makeViewModel() -> GenericMapBlackListViewModel<IntIDProvider> {
        .init(localStorage: localStorage, idProvider: IntIDProvider())
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
}

private extension String {

    static let newItemText = Strings.MapBlackList.newItemText
}
