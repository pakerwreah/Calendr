//
//  MapBlackListViewModel.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI

typealias MapBlackListViewModel = GenericMapBlackListViewModel<UUIDProvider>

@Observable
class GenericMapBlackListViewModel<IDProvider: IDProviding> {

    struct Item: Identifiable, Equatable {
        let id: IDProvider.ID
        var text: String
    }

    var items: [Item]
    var selection: Set<Item.ID> = []
    var canRemove: Bool { !selection.isEmpty }

    private let localStorage: LocalStorageProvider
    private let idProvider: IDProvider

    init(localStorage: LocalStorageProvider, idProvider: IDProvider = UUIDProvider()) {

        self.localStorage = localStorage
        self.idProvider = idProvider

        items = localStorage.showMapBlacklistItems.map {
            Item(id: idProvider.next(), text: $0)
        }
    }

    func save() {
        localStorage.showMapBlacklistItems = items.map(\.text)
    }

    func newItem() -> Item.ID {
        let newItem = Item(id: idProvider.next(), text: Strings.MapBlackList.newItemText)

        items.append(newItem)
        selection = [newItem.id]

        return newItem.id
    }

    func removeSelected() {
        items.removeAll { selection.contains($0.id) }
        save()
    }
}
