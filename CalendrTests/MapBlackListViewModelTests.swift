//
//  MapBlackListViewModelTests.swift
//  Calendr
//
//  Created by Paker on 29/10/2025.
//

import XCTest
@testable import Calendr

class MapBlackListViewModelTests: XCTestCase {

    let localStorage = MockLocalStorageProvider()

    func makeViewModel() -> GenericMapBlackListViewModel<IntIDProvider> {
        .init(localStorage: localStorage, idProvider: IntIDProvider())
    }

    func testViewModel_initialState() {

        registerDefaultPrefs(in: localStorage)

        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.items, [
            .init(id: 1, text: "Microsoft Teams"),
            .init(id: 2, text: "Google Meet"),
            .init(id: 3, text: "Discord"),
            .init(id: 4, text: "Slack"),
            .init(id: 5, text: "Zoom"),
        ])
        XCTAssertTrue(viewModel.selection.isEmpty)
        XCTAssertFalse(viewModel.canRemove)
    }

    func testViewModel_withSelection_canRemoveItems() {

        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.canRemove)
        viewModel.selection = [1]
        XCTAssertTrue(viewModel.canRemove)
    }

    func testViewModel_removeSelected() {

        let viewModel = makeViewModel()

        viewModel.items = (1...4).map {
            .init(id: $0, text: "Test \($0)")
        }

        viewModel.selection = [1, 3]
        viewModel.removeSelected()

        XCTAssertEqual(viewModel.items.map(\.id), [2, 4])
        XCTAssertEqual(localStorage.showMapBlacklistItems, ["Test 2", "Test 4"])
    }

    func testViewModel_newItems() {

        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.items.isEmpty)

        XCTAssertEqual(viewModel.newItem(), 1)
        XCTAssertEqual(viewModel.selection, [1])
        XCTAssertEqual(viewModel.items, [.init(id: 1, text: .newItemText)])
        XCTAssertTrue(localStorage.showMapBlacklistItems.isEmpty)

        XCTAssertEqual(viewModel.newItem(), 2)
        XCTAssertEqual(viewModel.selection, [2])
        XCTAssertEqual(viewModel.items, [.init(id: 1, text: .newItemText), .init(id: 2, text: .newItemText)])
        XCTAssertTrue(localStorage.showMapBlacklistItems.isEmpty)

        viewModel.items[0].text = "Edited Item"
        viewModel.save()

        XCTAssertEqual(localStorage.showMapBlacklistItems, ["Edited Item", .newItemText])
    }
}

private extension String {

    static let newItemText = Strings.MapBlackList.newItemText
}
