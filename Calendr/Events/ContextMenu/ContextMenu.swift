//
//  ContextMenu.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

protocol ContextMenuAction {
    var icon: NSImage? { get }
    var title: String { get }
}

extension ContextMenuAction {
    var icon: NSImage? { nil }
}

enum ContextMenuViewModelItem<Action: ContextMenuAction> {
    case separator
    case action(Action)
}

extension ContextMenuViewModelItem: Equatable where Action: Equatable { }

protocol ContextMenuViewModel {
    associatedtype Action: ContextMenuAction
    typealias ActionItem = ContextMenuViewModelItem<Action>

    var items: [ActionItem] { get }
    var actionCallback: Observable<Void> { get }

    func triggerAction(_ action: Action)
}

private class ContextMenuItem<Action: ContextMenuAction>: NSMenuItem {

    private let value: Action
    private let trigger: (Action) -> Void

    init(action: Action, trigger: @escaping (Action) -> Void) {
        self.value = action
        self.trigger = trigger
        super.init(title: action.title, action: #selector(selected), keyEquivalent: "")
        self.target = self
        self.image = action.icon
    }

    @objc private func selected() {
        trigger(value)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContextMenu<ViewModel: ContextMenuViewModel>: NSMenu {

    init(viewModel: ViewModel) {

        super.init(title: "")

        for item in viewModel.items {
            switch item {
            case .separator:
                addItem(.separator())
            case .action(let action):
                addItem(ContextMenuItem(action: action, trigger: viewModel.triggerAction))
            }
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

