//
//  MapBlackListViewModel.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI
import RxSwift

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

    var regexText: String {
        didSet {
            guard regexText != oldValue else { return }
            regexChangedSubject.onNext(())
        }
    }
    var isRegexInvalid: Bool
    var isRegexVisible: Bool

    private let localStorage: LocalStorageProvider
    private let idProvider: IDProvider

    private let regexChangedSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    init(
        localStorage: LocalStorageProvider,
        idProvider: IDProvider = UUIDProvider(),
        scheduler: SchedulerType
    ) {

        self.localStorage = localStorage
        self.idProvider = idProvider

        items = localStorage.showMapBlacklistItems.filter(\.isNotBlank).map {
            Item(id: idProvider.next(), text: $0)
        }

        let regexText = localStorage.showMapBlacklistRegex ?? ""
        self.regexText = regexText

        isRegexVisible = regexText.isNotBlank
        isRegexInvalid = !isValidRegex(regexText)

        regexChangedSubject
            .debounce(.milliseconds(300), scheduler: scheduler)
            .bind { [weak self] in
                self?.saveRegex()
            }
            .disposed(by: disposeBag)
    }

    func save() {
        saveItems()
        saveRegex()
    }

    private func saveItems() {
        localStorage.showMapBlacklistItems = items.map(\.text).filter(\.isNotBlank)
    }

    private func saveRegex() {
        isRegexInvalid = !isValidRegex(regexText)

        guard !isRegexInvalid else { return }

        localStorage.showMapBlacklistRegex = regexText.isNotBlank ? regexText : nil
    }

    func newItem() -> Item.ID {
        let newItem = Item(id: idProvider.next(), text: Strings.MapBlackList.newItemText)

        items.append(newItem)
        selection = [newItem.id]

        return newItem.id
    }

    func removeSelected() {
        items.removeAll { selection.contains($0.id) }
        selection = []
        save()
    }
}

private func isValidRegex(_ pattern: String) -> Bool {
    guard pattern.isNotBlank else { return true }
    return (try? Regex(pattern)) != nil
}
