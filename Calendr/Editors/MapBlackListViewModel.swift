//
//  MapBlackListViewModel.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI

@Observable
class MapBlackListViewModel {

    struct Item: Identifiable {
        let id = UUID()
        var text: String
    }

    var items: [Item]
    var selection: Set<Item.ID> = []

    private let localStorage: LocalStorageProvider

    var canRemove: Bool { !selection.isEmpty }

    init(localStorage: LocalStorageProvider) {

        self.localStorage = localStorage

        items = localStorage.showMapBlacklistItems.map(Item.init(text:))
    }

    func save() {
        localStorage.showMapBlacklistItems = items.map(\.text)
    }

    func newItem() -> Item.ID {
        let newItem = Item(text: "New Item")

        items.append(newItem)
        selection = [newItem.id]

        return newItem.id
    }

    func removeSelected() {
        items.removeAll { selection.contains($0.id) }
        save()
    }
}
